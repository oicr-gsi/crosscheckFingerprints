version 1.0
workflow crosscheckFingerprints {
    input {
        Array[File] inputs
        String? cachedFilePath
        String haplotypeMapFileName
        String haplotypeMapDir = "$CROSSCHECKFINGERPRINTS_HAPLOTYPE_MAP_ROOT"
        String outputPrefix = "output"
        String crosscheckBy = "SAMPLE"
        Boolean calculateTumorAwareResults = false
    }
    String haplotypeMap = "~{haplotypeMapDir}/~{haplotypeMapFileName}"

    parameter_meta {
        inputs: "A list of SAM/BAM/VCF files to fingerprint."
        cachedFilePath: "Previous output of this workflow. If given, only new comparisons will be calculated."
        haplotypeMapFileName: "The file name that lists a set of SNPs, optionally arranged in high-LD blocks, to be used for fingerprinting."
        haplotypeMapDir: "The directory that contains haplotype map files. By default the modulator data directory."
        outputPrefix: "Text to prepend to all output."
        crosscheckBy: "Specificies which data-type should be used as the basic comparison unit. Fingerprints from readgroups can be rolled-up to the LIBRARY, SAMPLE, or FILE level before being compared. Fingerprints from VCF can be be compared by SAMPLE or FILE."
        calculateTumorAwareResults: "Specifies whether the Tumor-aware result should be calculated. These are time consuming and can roughly double the runtime of the tool. When crosschecking many groups not calculating the tumor-aware results can result in a significant speedup."
    }

    meta {
        author: "Savo Lazic"
        email: "savo.lazic@oicr.on.ca"
        description: "Checks if all the genetic data within a set of files appear to come from the same individual by using Picard [CrosscheckFingerprints](https://gatk.broadinstitute.org/hc/en-us/articles/360037594711-CrosscheckFingerprints-Picard-)"
        dependencies:
        [
            {
                name: "picard/3.1.0",
                url: "https://github.com/broadinstitute/picard/releases/tag/3.1.0"
            },
            {
                name: "crosscheckfingerprints-haplotype-map/20230324",
                url: "https://github.com/oicr-gsi/fingerprint_maps"
            }
        ]
        output_meta: {
            crosscheckMetrics: {
                description: "The crosschecksMetrics file produced by Picard CrosscheckFingerprints",
                vidarr_label: "crosscheckMetrics"
            }
        }
    }

    # Picard allows the input to be a file of input paths, so make a file from the input array
    # This also makes it easy to compare cached paths to input paths
    call inputsToFile {
        input: 
            inputs = inputs
    }

    # Without a cached file, compare all libraries against each other (L^2)
    if (!defined(cachedFilePath)) {
        call runCrosscheckFingerprints {
            input:
                compare = inputsToFile.inputAsFile,
                haplotypeMap = haplotypeMap,
                outputPrefix = outputPrefix,
                crosscheckBy = crosscheckBy,
                calculateTumorAwareResults = calculateTumorAwareResults
        }
    }

    if (defined(cachedFilePath)) {
        String sf = select_first([cachedFilePath])
        
        # Calculate new, stale, and cached inputs. Also give cleaned cache file (without the stupid header)
        call usePowerOfCache {
            input:
                inputsAsFile = inputsToFile.inputAsFile,
                cachedFilePath = sf
        }

        # If there are no new inputs, no need for any new calculations
        if (usePowerOfCache.newCount > 0 ) {
            # Compare new inputs against all inputs
            call runCrosscheckFingerprints as runCached {
                input:
                    compare = usePowerOfCache.newInput,
                    compareAgainst = inputsToFile.inputAsFile,
                    haplotypeMap = haplotypeMap,
                    outputPrefix = outputPrefix,
                    crosscheckBy = crosscheckBy,
                    calculateTumorAwareResults = calculateTumorAwareResults
            }

            # Do the inverse. Compare cached inputs against new inputs
            # This ensures that the matrix remains symmetrical
            call runCrosscheckFingerprints as runCachedInverse {
                input:
                    compare = usePowerOfCache.cachedInput,
                    compareAgainst = usePowerOfCache.newInput,
                    haplotypeMap = haplotypeMap,
                    outputPrefix = outputPrefix,
                    crosscheckBy = crosscheckBy,
                    calculateTumorAwareResults = calculateTumorAwareResults
            }
        }

        # Mush the various outputs together, removing the stale files from the cache
        call createNewCrosscheckFingerprints {
            input:
                cleanedCache = usePowerOfCache.cleanedCacheFile,
                stale = usePowerOfCache.stale,
                newCrosscheckFingerprints = runCached.crosscheckMetrics,
                newInverseCrosscheckFingerprints = runCachedInverse.crosscheckMetrics,
                outputPrefix = outputPrefix
        }
    }

    File metrics = select_first([runCrosscheckFingerprints.crosscheckMetrics, createNewCrosscheckFingerprints.crosscheckMetrics])

    output {
        File crosscheckMetrics = metrics
    }
}

task runCrosscheckFingerprints {
    input {
        File compare
        File? compareAgainst
        String haplotypeMap
        String outputPrefix
        String crosscheckBy
        Boolean calculateTumorAwareResults
        Int picardMaxMemMb = 3000
        Int exitCodeWhenMismatch = 0
        Int exitCodeWhenNoValidChecks = 0
        Float lodThreshold = 0.0
        String validationStringency = "SILENT"
        String modules = "picard/3.1.0 crosscheckfingerprints-haplotype-map/20230324"
        Int threads = 4
        Int jobMemory = 6
        Int timeout = 6
    }

    parameter_meta {
        compare: "A file listing VCF files to fingerprint."
        compareAgainst: "A file listing VCF files to compare against. If this is supplied, VCF files in `compare` will be compared against files listed here."
        haplotypeMap: "The file that lists a set of SNPs, optionally arranged in high-LD blocks, to be used for fingerprinting."
        outputPrefix: "Text to prepend to all output."
        crosscheckBy: "Specificies which data-type should be used as the basic comparison unit. Fingerprints from readgroups can be 'rolled-up' to the LIBRARY, SAMPLE, or FILE level before being compared. Fingerprints from VCF can be be compared by SAMPLE or FILE."
        calculateTumorAwareResults: "Specifies whether the Tumor-aware result should be calculated. These are time consuming and can roughly double the runtime of the tool. When crosschecking many groups not calculating the tumor-aware results can result in a significant speedup."
        picardMaxMemMb: {
            description: "Passed to Java -Xmx (in Mb).",
            vidarr_retry: true
        }
        exitCodeWhenMismatch: "When one or more mismatches between groups is detected, exit with this value instead of 0."
        exitCodeWhenNoValidChecks: "When all LOD score are zero, exit with this value."
        lodThreshold: "If any two groups (with the same sample name) match with a LOD score lower than the threshold the tool will exit with a non-zero code to indicate error. Program will also exit with an error if it finds two groups with different sample name that match with a LOD score greater than -LOD_THRESHOLD. LOD score 0 means equal likelihood that the groups match vs. come from different individuals, negative LOD score -N, mean 10^N time more likely that the groups are from different individuals, and +N means 10^N times more likely that the groups are from the same individual."
        validationStringency: "Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. See https://jira.oicr.on.ca/browse/GC-8372 for why this is set to SILENT for OICR purposes."
        modules: "Modules to load for this workflow."
        threads: "Requested CPU threads."
        jobMemory: {
            description: "Memory (GB) allocated for this job.",
            vidarr_retry: true
        }
        timeout: {
            description: "Number of hours before task timeout.",
            vidarr_retry: true
        }
    }

    command <<<
        set -eu -o pipefail

        java -Xmx~{picardMaxMemMb}M -jar $PICARD_ROOT/picard.jar CrosscheckFingerprints \
        INPUT=~{compare} \
        ~{if defined(compareAgainst) then "SECOND_INPUT=~{select_first([compareAgainst])}" else ""} \
        ~{if defined(compareAgainst) then "CROSSCHECK_MODE=CHECK_ALL_OTHERS" else ""} \
        CALCULATE_TUMOR_AWARE_RESULTS=~{if calculateTumorAwareResults then "true" else "false"} \
        HAPLOTYPE_MAP=~{haplotypeMap} \
        OUTPUT=temp_metrics.txt \
        NUM_THREADS=~{threads} \
        EXIT_CODE_WHEN_MISMATCH=~{exitCodeWhenMismatch} \
        EXIT_CODE_WHEN_NO_VALID_CHECKS=~{exitCodeWhenNoValidChecks} \
        CROSSCHECK_BY=~{crosscheckBy} \
        LOD_THRESHOLD=~{lodThreshold} \
        VALIDATION_STRINGENCY=~{validationStringency}

        grep -vE '^\s*$|^#' temp_metrics.txt > ~{outputPrefix}.crosscheck_metrics.txt
    >>>

    output {
        File crosscheckMetrics = "~{outputPrefix}.crosscheck_metrics.txt"
    }

    meta {
        output_meta: {
            crosscheckMetrics: "The crosschecksMetrics file produced by Picard CrosscheckFingerprints"
        }
    }

    runtime {
        modules: "~{modules}"
        memory:  "~{jobMemory} GB"
        cpu:     "~{threads}"
        timeout: "~{timeout}"
    }
}

task usePowerOfCache {
    input {
        File inputsAsFile
        String cachedFilePath
        Int threads = 1
        Int jobMemory = 1
        Int timeout = 1
    }

    parameter_meta {
        inputsAsFile: "The file that contains the input paths"
        cachedFilePath: "File path of cache"
        threads: "Requested CPU threads."
        jobMemory: "Memory (GB) allocated for this job."
        timeout: "Number of hours before task timeout."
    }

    command <<<
        set -eu -o pipefail

        grep -vE '^\s*$|^#' ~{cachedFilePath} > cleaned_cache_file.txt

        awk -F'\t' 'NR > 1 {print $19}' cleaned_cache_file.txt | \
            sed 's|file://||' | \
            sort | uniq > cache.txt
 
        sort ~{inputsAsFile}  | uniq > inputs.txt

        comm -23 inputs.txt cache.txt > new.txt
        comm -13 inputs.txt cache.txt > stale.txt
        comm -12 inputs.txt cache.txt > cached.txt

        # this avoids `wc -l` adding the file name to the output
        wc -l < new.txt > new_count.txt
        wc -l < stale.txt > stale_count.txt
        wc -l < cached.txt > cached_count.txt
    >>>

    output {
        File newInput = "new.txt"
        File stale = "stale.txt"
        File cachedInput = "cached.txt"
        File cleanedCacheFile = "cleaned_cache_file.txt"
        Int newCount = read_int("new_count.txt") 
        Int staleCount = read_int("stale_count.txt")
        Int cachedCount = read_int("cached_count.txt")
    }

    meta {
        output_meta: {
            newInput: "File containing new input paths that need to compared against everything else",
            stale: "File containing stale input paths that need to be removed from the cache",
            cachedInput: "File containing cached paths that need to be compared against the new inputs",
            cleanedCacheFile: "The cached file with header removed",
            newCount: "Number of new inputs",
            staleCount: "Number of stale cached paths",
            cachedCount: "Number of retained cached paths"
        }
    }

    runtime {
        memory:  "~{jobMemory} GB"
        cpu:     "~{threads}"
        timeout: "~{timeout}"
    }
}

task inputsToFile {
    # Tried this in the `workflow` scope and `write_lines` doesn't work. So `task` it is.

    input {
        Array[File] inputs
        Int threads = 1
        Int jobMemory = 1
        Int timeout = 1
    }

    parameter_meta {
        inputs: "The inputs to write to a file"
        threads: "Requested CPU threads."
        jobMemory: "Memory (GB) allocated for this job."
        timeout: "Number of hours before task timeout."
    }

    # Explicitly cast to string, as using `File` does not resolve the symbolic links that Cromwell generates
    Array[String] inputs_str = inputs
    File out = write_lines(inputs_str)

    command <<<
    # WDL made me put this command block here
    >>>

    output {
        File inputAsFile = out 
    }

    meta {
        output_meta: {
            inputAsFile: "The file with where the inputs were written"
        }
    }

    runtime {
        memory:  "~{jobMemory} GB"
        cpu:     "~{threads}"
        timeout: "~{timeout}"
    }
}

task createNewCrosscheckFingerprints {
    input {
        File cleanedCache
        File stale
        File? newCrosscheckFingerprints
        File? newInverseCrosscheckFingerprints
        String outputPrefix
        Int threads = 1
        Int jobMemory = 1
        Int timeout = 1
    }

    parameter_meta {
        cleanedCache: "The cache file with the comment header removed"
        stale: "The stale file containing stale file paths. Any line in the cache that contains that file path will be removed"
        newCrosscheckFingerprints: "Output of crosscheckFingerprints comparing new inputs compared against all inputs"
        newInverseCrosscheckFingerprints: "Output of crosscheckFingerprints comparing cached input against new input"
        outputPrefix: "Text to prepend to all output."
        threads: "Requested CPU threads."
        jobMemory: "Memory (GB) allocated for this job."
        timeout: "Number of hours before task timeout."
    }

    command <<<
        set -eu -o pipefail
        ~{if defined(newCrosscheckFingerprints) then "sed 1d ~{select_first([newCrosscheckFingerprints])} > new.txt" else "touch new.txt"}
        ~{if defined(newInverseCrosscheckFingerprints) then "sed 1d ~{select_first([newInverseCrosscheckFingerprints])} > new_inverse.txt" else "touch new_inverse.txt"}
        grep -vf ~{stale} ~{cleanedCache} | cat - new_inverse.txt new.txt > ~{outputPrefix}.crosscheck_metrics.txt
    >>>

    output {
        File crosscheckMetrics = "~{outputPrefix}.crosscheck_metrics.txt"
    }

    meta {
        output_meta: {
            crosscheckMetrics: "The concatenated file containing cached and newly computer rows"
        }
    }

    runtime {
        memory:  "~{jobMemory} GB"
        cpu:     "~{threads}"
        timeout: "~{timeout}"
    }
}

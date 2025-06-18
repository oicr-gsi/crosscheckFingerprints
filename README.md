# crosscheckFingerprints

Checks if all the genetic data within a set of files appear to come from the same individual by using Picard [CrosscheckFingerprints](https://gatk.broadinstitute.org/hc/en-us/articles/360037594711-CrosscheckFingerprints-Picard-)

## Overview

## Dependencies

* [picard 3.1.0](https://github.com/broadinstitute/picard/releases/tag/3.1.0)
* [crosscheckfingerprints-haplotype-map 20230324](https://github.com/oicr-gsi/fingerprint_maps)


## Usage

### Cromwell
```
java -jar cromwell.jar run crosscheckFingerprints.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`inputs`|Array[File]|A list of SAM/BAM/VCF files to fingerprint.
`haplotypeMapFileName`|String|The file name that lists a set of SNPs, optionally arranged in high-LD blocks, to be used for fingerprinting.


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`cachedFilePath`|String?|None|Previous output of this workflow. If given, only new comparisons will be calculated.
`haplotypeMapDir`|String|"$CROSSCHECKFINGERPRINTS_HAPLOTYPE_MAP_ROOT"|The directory that contains haplotype map files. By default the modulator data directory.
`outputPrefix`|String|"output"|Text to prepend to all output.
`crosscheckBy`|String|"SAMPLE"|Specificies which data-type should be used as the basic comparison unit. Fingerprints from readgroups can be rolled-up to the LIBRARY, SAMPLE, or FILE level before being compared. Fingerprints from VCF can be be compared by SAMPLE or FILE.
`calculateTumorAwareResults`|Boolean|false|Specifies whether the Tumor-aware result should be calculated. These are time consuming and can roughly double the runtime of the tool. When crosschecking many groups not calculating the tumor-aware results can result in a significant speedup.


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`inputsToFile.threads`|Int|1|Requested CPU threads.
`inputsToFile.jobMemory`|Int|1|Memory (GB) allocated for this job.
`inputsToFile.timeout`|Int|1|Number of hours before task timeout.
`runCrosscheckFingerprints.compareAgainst`|File?|None|A file listing VCF files to compare against. If this is supplied, VCF files in `compare` will be compared against files listed here.
`runCrosscheckFingerprints.picardMaxMemMb`|Int|3000|Passed to Java -Xmx (in Mb).
`runCrosscheckFingerprints.exitCodeWhenMismatch`|Int|0|When one or more mismatches between groups is detected, exit with this value instead of 0.
`runCrosscheckFingerprints.exitCodeWhenNoValidChecks`|Int|0|When all LOD score are zero, exit with this value.
`runCrosscheckFingerprints.lodThreshold`|Float|0.0|If any two groups (with the same sample name) match with a LOD score lower than the threshold the tool will exit with a non-zero code to indicate error. Program will also exit with an error if it finds two groups with different sample name that match with a LOD score greater than -LOD_THRESHOLD. LOD score 0 means equal likelihood that the groups match vs. come from different individuals, negative LOD score -N, mean 10^N time more likely that the groups are from different individuals, and +N means 10^N times more likely that the groups are from the same individual.
`runCrosscheckFingerprints.validationStringency`|String|"SILENT"|Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. See https://jira.oicr.on.ca/browse/GC-8372 for why this is set to SILENT for OICR purposes.
`runCrosscheckFingerprints.modules`|String|"picard/3.1.0 crosscheckfingerprints-haplotype-map/20230324"|Modules to load for this workflow.
`runCrosscheckFingerprints.threads`|Int|4|Requested CPU threads.
`runCrosscheckFingerprints.jobMemory`|Int|6|Memory (GB) allocated for this job.
`runCrosscheckFingerprints.timeout`|Int|6|Number of hours before task timeout.
`usePowerOfCache.threads`|Int|1|Requested CPU threads.
`usePowerOfCache.jobMemory`|Int|1|Memory (GB) allocated for this job.
`usePowerOfCache.timeout`|Int|1|Number of hours before task timeout.
`runCached.picardMaxMemMb`|Int|3000|Passed to Java -Xmx (in Mb).
`runCached.exitCodeWhenMismatch`|Int|0|When one or more mismatches between groups is detected, exit with this value instead of 0.
`runCached.exitCodeWhenNoValidChecks`|Int|0|When all LOD score are zero, exit with this value.
`runCached.lodThreshold`|Float|0.0|If any two groups (with the same sample name) match with a LOD score lower than the threshold the tool will exit with a non-zero code to indicate error. Program will also exit with an error if it finds two groups with different sample name that match with a LOD score greater than -LOD_THRESHOLD. LOD score 0 means equal likelihood that the groups match vs. come from different individuals, negative LOD score -N, mean 10^N time more likely that the groups are from different individuals, and +N means 10^N times more likely that the groups are from the same individual.
`runCached.validationStringency`|String|"SILENT"|Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. See https://jira.oicr.on.ca/browse/GC-8372 for why this is set to SILENT for OICR purposes.
`runCached.modules`|String|"picard/3.1.0 crosscheckfingerprints-haplotype-map/20230324"|Modules to load for this workflow.
`runCached.threads`|Int|4|Requested CPU threads.
`runCached.jobMemory`|Int|6|Memory (GB) allocated for this job.
`runCached.timeout`|Int|6|Number of hours before task timeout.
`runCachedInverse.picardMaxMemMb`|Int|3000|Passed to Java -Xmx (in Mb)
`runCachedInverse.exitCodeWhenMismatch`|Int|0|When one or more mismatches between groups is detected, exit with this value instead of 0.
`runCachedInverse.exitCodeWhenNoValidChecks`|Int|0|When all LOD score are zero, exit with this value.
`runCachedInverse.lodThreshold`|Float|0.0|If any two groups (with the same sample name) match with a LOD score lower than the threshold the tool will exit with a non-zero code to indicate error. Program will also exit with an error if it finds two groups with different sample name that match with a LOD score greater than -LOD_THRESHOLD. LOD score 0 means equal likelihood that the groups match vs. come from different individuals, negative LOD score -N, mean 10^N time more likely that the groups are from different individuals, and +N means 10^N times more likely that the groups are from the same individual.
`runCachedInverse.validationStringency`|String|"SILENT"|Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. See https://jira.oicr.on.ca/browse/GC-8372 for why this is set to SILENT for OICR purposes.
`runCachedInverse.modules`|String|"picard/3.1.0 crosscheckfingerprints-haplotype-map/20230324"|Modules to load for this workflow.
`runCachedInverse.threads`|Int|4|Requested CPU threads.
`runCachedInverse.jobMemory`|Int|6|Memory (GB) allocated for this job.
`runCachedInverse.timeout`|Int|6|Number of hours before task timeout.
`createNewCrosscheckFingerprints.threads`|Int|1|Requested CPU threads.
`createNewCrosscheckFingerprints.jobMemory`|Int|1|Memory (GB) allocated for this job.
`createNewCrosscheckFingerprints.timeout`|Int|1|Number of hours before task timeout.


### Outputs

Output | Type | Description | Labels
---|---|---|---
`crosscheckMetrics`|File|The crosschecksMetrics file produced by Picard CrosscheckFingerprints|vidarr_label: crosscheckMetrics


## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_

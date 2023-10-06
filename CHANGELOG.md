## 2.1.0 - 2023-10-06
- Switch from GATK 4.2 to Picard 3.1. GATK 4.2 is 50 times slower than Picard for unknown reason.

## 2.0.0 - 2023-09-25
- Switched from Picard 2.21 to GATK 4.2. This has been shown to produce significantly different LOD scores
- Removed the `additionalParameters` parameter. That parameter was a bad design decision.
- Testing is done by direct string comparison, rather than md5sum
- Bumped the haplotype file module (the files used in this workflow have not changed in the updated module)

## 1.0.1 - 2020-05-31
- Vidarr migration

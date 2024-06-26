## 2.1.0 - 2024-06-25
[GRD-797](https://jira.oicr.on.ca/browse/GRD-797) - add vidarr labels to outputs (changes to medata only)
## 2.0.0 - 2023-09-25
- Switched from Picard 2.21 to GATK 4.2. This has been shown to produce significantly different LOD scores
- Removed the `additionalParameters` parameter. That parameter was a bad design decision.
- Testing is done by direct string comparison, rather than md5sum
- Bumped the haplotype file module (the files used in this workflow have not changed in the updated module)

## 1.0.1 - 2020-05-31
- Vidarr migration

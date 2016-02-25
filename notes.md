# Notes

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [Notes](#notes)
    - [Big Ugly Blockers (BUBs)](#big-ugly-blockers-bubs)

<!-- markdown-toc end -->

## Big Ugly Blockers (BUBs)

- rkt gc is broken on Centos:
  [upstream bug report](https://github.com/coreos/rkt/issues/1922)
- rkt 1.0.0 is not configured to use the correct directory for stage1 images:
  [upstream bug report](https://github.com/coreos/rkt/issues/2221)
- Centos SELinux policy is incompatible with rkt:
  [upstream bug report](https://github.com/coreos/rkt/issues/1727)

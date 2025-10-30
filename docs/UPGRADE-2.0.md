# Upgrade from v1.x to v2.x

Please consult the `tests` directory for reference configurations. If you find a bug, please open an issue with supporting configuration to reproduce.

## List of backwards incompatible changes

-

## Additional changes

### Added

-

### Modified

-

### Removed

-

### Variable and output changes

1. Removed variables:

    -

2. Renamed variables:

    -

3. Added variables:

    -

4. Removed outputs:

    -

5. Renamed outputs:

    -

6. Added outputs:

    -

## Upgrade Migrations

### Diff of Before vs After

```diff
 module "eks_blueprints_addons" {
  source  = "aws-blueprints/eks-blueprints-addons/aws"
-  version = "1.22"
+  version = "2.0"

  # Truncated for brevity, only the changed parts are shown

}
```

### State Move Commands

TBD

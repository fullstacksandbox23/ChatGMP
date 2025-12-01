# Provisions resources for ChatGMP (Chat Good Manufacturing Practices)

Run outside ci-pipeline and make it a manual trigger to proceed, after the outside-ci-run was successful.

Highly inspired from [fullstacksandbox23](https://github.com/arnoldknott/fullstacksandbox23) repo.

## Deploying infrastructure

Needs manual approval before apply!

### ... from localhost:

```bash
./scripts/deploy_infrastructure.sh
```

in projects root directory

### ... in CI/CD pipeline

commit changes to infrastructure and push to repo.
follow the activity in Github Actions pipeline. 


## Structure of scripts

- code formatting before commit `tofu fmt`
- initializing `tofu init`
- selecting workspace based on git branch `tofu workspace select <dev|stage|prod>`
- generating the plan file `tofu plan`
- manual approval!
- applying the plan file `tofu apply`
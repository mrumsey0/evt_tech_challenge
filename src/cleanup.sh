#!/bin/bash

# destroy azure resources and logout
terraform destroy -auto-approve && az logout
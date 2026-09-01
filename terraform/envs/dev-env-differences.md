# what will be actullay different from dev environment:

1. in backend.tf chagne the key: value to a different state file 
2. in variables.tf file change the CIDR to be something different like 10.1.0.0/16, and the same with subnets ofcourse. 
3. in main.tf you would allow more than one nat gateway for HA , the line responsiple for that is
   single_nat_gateway = true   _make it false_
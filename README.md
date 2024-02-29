# Infrastructure

## Infrastructure Diagram:-
![alt text](Image2.png)
Total AWS resources:-
1. VPC
2. Subnet (2 Public, 2 Private)
3. Route Table (1 Public, 1 Private)
4. Internet Gateway, Nat Gateway
5. Loadbalancer (Balance the app running in private subnet)
6. Security Group

## Ops Diagram:-
![alt text](Image.png)

## Info About Branches
1. terraform branch:- This branch is related to infrastructure, all the terraform code are stored in terraform branch.
2. ansible branch:- This branch is related to configuration management, all the ansible roles are stored in ansible branch.

#!/bin/bash
cd /Users/putinan/development/DevOps/develop/main_backend

# Fix all instances where User is created without name field
sed -i '' '
/User user = new User();/{
N
N
N
s/User user = new User();\s*user\.setUsername/User user = new User();\
        user.setName("Test User");\
        user.setUsername/
}' src/test/java/com/concert/repository/UserRepositoryDockerTest.java

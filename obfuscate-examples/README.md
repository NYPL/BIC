# Obfuscate Examples

This folder demonstrates using bcrypt to obfuscate identifiers in a variety of languages to generate consistent hashes.

## Java

```
cd java
mvn install; mvn package
BCRYPT_SALT=[super secret salt] java -jar target/gs-maven-0.1.0.jar p12345678
```

## Ruby

```
cd ruby
BCRYPT_SALT=[super secret salt] ruby obfuscate.rb p12345678
```

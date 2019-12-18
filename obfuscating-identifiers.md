# Obfuscating Identifiers in BIC

We need an algorithm for obfuscating sensitive identifiers such that:
 * a given identifier produces the same obfuscated value every time
 * the hashing function can be run on a variety of systems to produce consistent hashes
 * the obfuscated value can not easily be decoded backwards into the original sensitive identifier

## Proposed method

We propose using `bcrypt` to hash sensitive identifiers (e.g. patron ids) with a salt as follows:

```ruby
require 'bcrypt'
def hash_sensitive_value (inp)
  hash = BCrypt::Engine.hash_secret inp, ENV['BCRYPT_SALT']
  BCrypt::Password.new(hash).checksum # Unclear why ruby-bcrypt calls the hash a "checksum"
end
```

Note that we're intentionally only using the hash part of the bcrypt output. Normally, bcrypt is used to generate a value that prepends the hashing algorithm, cost, and salt to the front of the hash. This serves a common use of bcrypt: An incoming plaintext value needs to be compared to a previously hashed value using an identical cost and salt. At no point in our workflow will we need to compare a plaintext value to a previously encrypted value. Also our salt must be kept secret. That being the case, it's necessary to strip the prefix from the hash value. The `ruby` example above does this using the `.checksum` method.

In Java:

```java
import org.springframework.security.crypto.bcrypt.*;
...
public String hashSensitiveValue(String inp) {
  String salt = System.getenv("BCRYPT_SALT");
  String obfuscatedValue = BCrypt.hashpw(inp, salt);
  // Strip the algorithm, cost, & salt prefix:
  obfuscatedValue = obfuscatedValue.substring(29);
  return obfuscatedValue;
}
```

See [obfuscate-examples](./obfuscate-examples/README.md) for full, runnable sample scripts.

In general, substringing the output of `bcrypt` starting at index 29 will give us the obfuscated id we want.

For example, if a full bcrypt hash value is:

```
$2a$07$dwk1yoKFIIhejOZJLmMH4uwo7cDpXB1JMmlMgpVvn.VrMqjt7iBJC
```

The component parts are:

| Hashing alg. | Cost | Salt                     | Hash (index 29)                   |
|--------------|------|--------------------------|-----------------------------------|
| `2a`         | `07` | `dwk1yoKFIIhejOZJLmMH4u` | `wo7cDpXB1JMmlMgpVvn.VrMqjt7iBJC` |

### Generating a salt

To generate a suitable value for `ENV['BCRYPT_SALT']`:

```ruby
require 'bcrypt'
salt = BCrypt::Engine.generate_salt
```

Given a stable `ENV['BCRYPT_SALT']`, this will generate stable hashes.

### Using Bcrypt in Ruby

Bcrypt is bound with native extensions, so your `bcrypt` gem in OSX can not be deployed to AWS Lambda. To build a project inside the target environment:

```bash
docker run -it --rm -v "$PWD":/var/task lambci/lambda:build-ruby2.5 bundle install --deployment
```

Assuming we use Travis for deployment, [there's prior art packaging an app with native-bound gems](https://github.com/NYPL/item-checkout-feed-updater/blob/development/.travis.yml#L11-L12).

There's also [a test Lambda deployment in nypl-digital-dev](https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/test-bcrypt?newFunction=true&tab=configuration)

## Concerns

### Speed

BCrypt is slow by design. This protects against brute force attacks. It may also pose a problem during peak circ traffic. We can control the `cost` applied to each hash via the salt. In the following salt, the cost is `08`:

```
$2a$08$7ZgiejHrtgoXsGj1RLfwme
```

Informal benchmarking using Ruby bcrypt on AWS lambda suggests following relationship of `cost` and the time required to hash a single value:

| cost | time to hash |
|------|--------------|
| `07` | 0.12s        |
| `08` | 0.24s        |
| `10` | 0.884s       |
| `12` | ~3s          |

The average observed circ-trans traffic is about 42/minute (computed from 488k/week, which [has been a typical week over the past month](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:graph=~(metrics~(~(~'AWS*2fKinesis~'PutRecords.Records~'StreamName~'CircTransData-production~(stat~'Sum~period~604800)))~view~'timeSeries~stacked~false~region~'us-east-1~start~'-P28D~end~'P0D);query=~'*7bAWS*2fKinesis*2cStreamName*7d*20circ)). The maximum rate at which circ-trans records have been written over the past 1 month was 330 in a single 1-minute period (on Nov 2, at 16:52 ET).

With that in mind, `07` (earlier I recommended `08`) may be a good starting `cost` as it will allow a max of 8+ transactions per second (or 480/min - plenty faster than the fastest observed circ-trans traffic). Note that changing the `cost` part of the salt produces a different hash value, so we should choose an initial `cost` we expect to stick with.

### Collisions

The possibility that two different identifiers produce the same hash value is non-zero, but very small. The encrypted output of `bcrypt` is 184 bits, meaning there are 2^184 possible values (24519928653854221733733552434404946937899825954937634816, or about 24 septendecillion). If we're hashing 10 million unique identifiers, there's a one in 2 quindecillion chance of collision.

## Alternative approaches

### Unique salts

> Note: We should consider feasability of salting on patron barcode

Generating individual salts for each distinct senstive value you want to encrypt is generally recommended, but may not be feasible in our case. Unique salts are only possible when you have *a stable identifier* to associate the generated salt with (e.g. a username/login). The only stable identifier we could associate with a unique salt would be the identifer we're encrypting, which by definition we don't want sitting in plaintext on any system. As an alternative, adding the `salt` to the broadcast circ-trans record would be useless because the circ-trans record will not contain the plaintext identifier (also, we want to avoid querying Redshift for every hash).

`Bcrypt-ruby` has a nice feature to encourage unique salt use. `BCrypt::Password.create` generates secure salts on the fly and produces a hash that appends the salt to the hashed value (with a default `cost` value). This ensures the generated hash uses a unique salt every time - unless you explicitly give it a specific salt. This is useful for workflows where you've previously hashed a secret (i.e. account creation) and you want to compare a plaintext secret to the retrieved hash (i.e. login). This is a fundamentally different workflow than the one we're facing; At no point in our workflow will we need to compare a plaintext identifier to a previously hashed identifier. Rather, we need a method that produces the same output given the same input without knowing anything about previous hash values.

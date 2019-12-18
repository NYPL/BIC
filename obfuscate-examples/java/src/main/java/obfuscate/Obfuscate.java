package obfuscate;

import org.springframework.security.crypto.bcrypt.*;

public class Obfuscate {

  public static String hashSensitiveValue(String inp) {

    String salt = System.getenv("BCRYPT_SALT");
    System.out.println("Hashing using salt: '" + salt + "'");

    String obfuscatedValue = BCrypt.hashpw(inp, salt);
    System.out.println(".. Full hash: " + obfuscatedValue);

    // Strip the algorithm, cost, & salt prefix:
    obfuscatedValue = obfuscatedValue.substring(29);
    return obfuscatedValue;
  }

  public static void main (String[] args) {

    System.out.println("Hashing: '" + args[0] + "'");

    String obfuscatedValue = hashSensitiveValue(args[0]);

    System.out.println("Final hashed value: '" + obfuscatedValue + "'");
  }
}

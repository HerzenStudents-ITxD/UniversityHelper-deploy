using System;
using System.Security.Cryptography;
using System.Text;

class Program
{
    static void Main(string[] args)
    {
        string salt = "Random_Salt";
        string login = "adminlogin";
        string password = "Admin_1234";
        string internalSalt = "UniversityHelper.SALT3";

        string input = $"{salt}{login}{password}{internalSalt}";
        byte[] inputBytes = Encoding.UTF8.GetBytes(input);
        byte[] hashBytes = SHA512.Create().ComputeHash(inputBytes);
        string hash = Convert.ToBase64String(hashBytes);

        Console.WriteLine("Generated hash:");
        Console.WriteLine(hash);
        Console.WriteLine("\nStored hash:");
        Console.WriteLine("9LpqjwFggNlzxIpXdouqAL8HgJvFSsEVhNNx891zEPKZD+Pvbib8gfVUGNeCw5/MDQX15wDT62xl+f7U7wGHkw==");
        Console.WriteLine("\nMatch: " + (hash == "9LpqjwFggNlzxIpXdouqAL8HgJvFSsEVhNNx891zEPKZD+Pvbib8gfVUGNeCw5/MDQX15wDT62xl+f7U7wGHkw=="));
    }
} 
require 'stringio'
require 'jose'
require 'json'
require 'base64'


# these are test values and were generated with a previous key that is no-longer in use. i will leave this here because it is valuable to understand
encrypted_jwt = "eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2Q0JDLUhTNTEyIiwia2lkIjoiOVBfaFB4WG8zeFlRVXRkbDhhdmtQMDh5V1ZWX0ppejVtMTZyZnpsSmVEcDVmT291cU55cGoyRy00NWVWcDMtSk5uMWNOcXoycGx0MFdiYlZFUnJSSVEifQ..P_6jMbUv9f-M7jm2OdHgBQ.25rya4jO7xU0vFx4RjpOpUnQSN3v4QmIZLce63pbU_U3sD_A7TMKC1ncKSV0TEO3a_yWlZwIOoOAAmsjqMMnrQlFpmmhw8XVztu0u97RVWRSc0QHiKMOX6qycCPbsd_Ts0h_YH1QxfzDAZF6IVb5m8Ut44_ZLzyu7sa_Eg7A0-XED-lfgckhFXGIjw5hxt-PaXDcRp6YeCJH0ghPWuNcaG-mcdYSXeqTiB9nzM4XNpQ4kehjR2k3jEbvbvD6PsIalxd8weIjH8nL1qcrpw0hXc0cNqw_LL61uXJD5Mnu3loe3yzOi5V4ydDdpYiuAMdjG1Sa4wMAqegRTWeviOVJFripJNBsLoySRg1UQuvZTQgjTMCaPjjTWiRAYvOw7-Foyk4xXtxWFBnPwxgR_7kT2w.VLHnXpVAJwHfIMwBTo6qDTE2oL3hWVyB3nAdiQ4yKlA"
derived_key = "6e38cbe40ce5a7050110db6d264fd8fc1432a07f84027d441ae2c90773892a74610714f579bcfd2b1824102baafeb3ca38b3e24335bd5f6f855caa625d5aef65"

symmetric_key = [derived_key].pack("H*")
jwk_oct512 = JOSE::JWK.from_oct(symmetric_key)
decrypted_payload, headers = JOSE::JWE.block_decrypt(jwk_oct512, encrypted_jwt)
payload = JSON.parse(decrypted_payload)

puts "Decrypted Payload: #{payload}"
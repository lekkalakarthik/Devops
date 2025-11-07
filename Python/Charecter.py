# from charset_normalizer import from_bytes

# raw_bytes = b'\xe4\xbd\xa0\xe5\xa5\xbd'  # "你好" in UTF-8
# results = from_bytes(raw_bytes)

# for result in results:
#     print("Encoding:", result.encoding)
#     print("Decoded text:", results.decoded)
#####################################################

# from charset_normalizer import from_bytes

# raw_bytes = b'\xe4\xbd\xa0\xe5\xa5\xbd'  # "你好" in UTF-8
# results = from_bytes(raw_bytes)

# for result in results:  # each result is a CharsetMatch
#     print("Encoding:", result.encoding)
#     print("Decoded text:", result.decode)
#     best_guess = results.best()
#     print(best_guess.encoding)
#     print(best_guess.decode)


# raw_bytes = b'\xe4\xbd\xa0\xe5\xa5\xbd'
# decoded = raw_bytes.decode("utf-8")
# print(decoded)  # 你好
##############


from charset_normalizer import from_bytes

raw_bytes = b'\xe4\xbd\xa0\xe5\xa5\xbd'  # "你好" in UTF-8
match = from_bytes(raw_bytes).best()     # get best guess
print("Encoding:", match.encoding)
print("Decoded text:", match.decode())   # <-- must work on 3.4.2

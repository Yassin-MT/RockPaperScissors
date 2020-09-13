from web3 import Web3

# used for commit and reveal scheme
# asks address, sign, and secret (a string)
# returns the hash, this will run locally on computer
# or on the front end of the Dapp

# need web3 installed

# accepts all variables
address = input('Enter Address: ')
address = Web3.toHex(hexstr = address)
address = Web3.toChecksumAddress(address)

sign = input('Enter Sign: ')
sign = int(sign)

secret = input('Enter Secret: ')

# solidity hashing function
result = Web3.soliditySha3(['address', 'uint256', 'string'], [address, sign, secret])

# prints resulting hash
print(Web3.toHex(result))

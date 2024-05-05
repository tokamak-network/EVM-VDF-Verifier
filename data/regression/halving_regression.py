import json
import numpy as np
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt

# Model definition
def model(x, a, b):
    return a * x + b

# Load data from JSON file
with open('../halving_data.json', 'r') as file:
    data = json.load(file)

# Extract values and corresponding exponents (x-axis)
length_data_2048 = np.array(data['2048']['length'])
gas_data_2048 = np.array(data['2048']['halving_cost']) / 10**6

length_data_3072 = np.array(data['3072']['length'])
gas_data_3072 = np.array(data['3072']['halving_cost']) / 10**6

# Curve fitting
initial_guess = [100, -100]
params_2048, _ = curve_fit(model, length_data_2048, gas_data_2048, p0=initial_guess)
params_3072, _ = curve_fit(model, length_data_3072, gas_data_3072, p0=initial_guess)

print(params_2048)
print(params_3072)

# Adjusting bar width and position for clarity
indices_2048 = np.arange(len(length_data_2048))  # Locations for the groups
quality = 1000

# Plotting for 2048-bit key
fig, ax1 = plt.subplots()
ax1.bar(indices_2048, gas_data_2048, color='darkgreen', label='Gas Used')
ax1.set_xlabel('Number of Proofs', fontsize=15)
ax1.set_ylabel('Gas used ($10^6$)', fontsize=15)
# ax1.set_title('2048-bit Key Regression')
ax1.grid(True)
fig.legend(loc='upper left', bbox_to_anchor=(0.13, 0.97))
plt.tight_layout()
plt.savefig('2048_halving_gas.png', dpi=quality)
plt.show()
plt.close()

# Adjusting indices for the 3072-bit key data
indices_3072 = np.arange(len(length_data_3072))

# Plotting for 3072-bit key
fig, ax1 = plt.subplots()
ax1.bar(indices_3072, gas_data_3072, color='darkgreen', label='Gas Used')
ax1.set_xlabel('Number of Proofs', fontsize=15)
ax1.set_ylabel('Gas used ($10^6$)', fontsize=15)
# ax1.set_title('3072-bit Key Regression')
ax1.grid(True)
fig.legend(loc='upper left', bbox_to_anchor=(0.13, 0.97))
plt.tight_layout()
plt.savefig('3072_halving_gas.png', dpi=quality)
plt.show()
plt.close()

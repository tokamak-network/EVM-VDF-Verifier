import json
import numpy as np
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt

# Model definition
def model(x, a, b):
    return a * x + b

# Load data from JSON file
with open('../intrinsic+dispatching.json', 'r') as file:
    data = json.load(file)

# Extract values and corresponding exponents (x-axis)
length_data_2048 = np.array(data['2048']['length'])
size_data_2048 = np.array(data['2048']['size']) / 1024  # Convert to KB
gas_data_2048 = data['2048']['gas']

length_data_3072 = np.array(data['3072']['length'])
size_data_3072 = np.array(data['3072']['size']) / 1024  # Convert to KB
gas_data_3072 = data['3072']['gas']

# Curve fitting
initial_guess = [1, 1]
params_2048, _ = curve_fit(model, length_data_2048, gas_data_2048, p0=initial_guess)
params_3072, _ = curve_fit(model, length_data_3072, gas_data_3072, p0=initial_guess)

# Adjusting bar width and position for clarity
bar_width = 0.4  # Set bar width
indices_2048 = np.arange(len(length_data_2048))  # Locations for the groups
quality = 1000

# Plotting for 2048-bit key
fig, ax1 = plt.subplots()
ax2 = ax1.twinx()  # Create a second y-axis for the size data
ax1.bar(indices_2048 - bar_width/2, gas_data_2048, width=bar_width, color='green', label='Gas Data')
ax2.bar(indices_2048 + bar_width/2, size_data_2048, width=bar_width, color='darkred', label='Size Data (KB)')
ax1.set_xlabel('Number of Proofs', fontsize=15)
ax1.set_ylabel('Gas Used', fontsize=15)
ax2.set_ylabel('Calldata (KB)', fontsize=15)
# ax1.set_title('2048-bit Key Regression')
ax1.grid(True)
fig.legend(loc='upper left', bbox_to_anchor=(0.16, 0.97))
plt.tight_layout()
plt.savefig('2048_regression.png', dpi=quality)
plt.show()
plt.close()

# Adjusting indices for the 3072-bit key data
indices_3072 = np.arange(len(length_data_3072))

# Plotting for 3072-bit key
fig, ax1 = plt.subplots()
ax2 = ax1.twinx()  # Create a second y-axis for the size data
ax1.bar(indices_3072 - bar_width/2, gas_data_3072, width=bar_width, color='green', label='Gas Used')
ax2.bar(indices_3072 + bar_width/2, size_data_3072, width=bar_width, color='darkred', label='Calldata (KB)')
ax1.set_xlabel('Number of Proofs', fontsize=15)
ax1.set_ylabel('Gas used', fontsize=15)
ax2.set_ylabel('Size (KB)', fontsize=15)
# ax1.set_title('3072-bit Key Regression')
ax1.grid(True)
fig.legend(loc='upper left', bbox_to_anchor=(0.16, 0.97))
plt.tight_layout()
plt.savefig('3072_size_gas.png', dpi=quality)
plt.show()
plt.close()

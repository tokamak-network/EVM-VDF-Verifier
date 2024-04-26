import json
import numpy as np
from sklearn.linear_model import LinearRegression
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt

# Model definition
def model(x, a, b):
    return a * x + b

# Load data from JSON file
with open('intrinsic+dispatching.json', 'r') as file:
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

# Plotting for 2048-bit key
fig, ax1 = plt.subplots()
ax2 = ax1.twinx()  # Create a second y-axis for the size data
ax1.scatter(length_data_2048, gas_data_2048, color='blue', label='Gas Data')
ax2.plot(length_data_2048, size_data_2048, color='green', label='Size Data (KB)', linestyle='--')
y_pred_2048 = params_2048[0] * length_data_2048 + params_2048[1]
ax1.plot(length_data_2048, y_pred_2048, color='red', label='Regression Line')
ax1.set_xlabel('Log2 of Exponent')
ax1.set_ylabel('precompileModExpGas')
ax2.set_ylabel('Size (KB)')
ax1.set_title('2048-bit Key Regression')
ax1.grid(True)
fig.legend(loc='upper right')
plt.savefig('2048_regression.png')
plt.close()

# Plotting for 3072-bit key
fig, ax1 = plt.subplots()
ax2 = ax1.twinx()  # Create a second y-axis for the size data
ax1.scatter(length_data_3072, gas_data_3072, color='blue', label='Gas Data')
ax2.plot(length_data_3072, size_data_3072, color='green', label='Size Data (KB)', linestyle='--')
y_pred_3072 = params_3072[0] * length_data_3072 + params_3072[1]
ax1.plot(length_data_3072, y_pred_3072, color='red', label='Regression Line')
ax1.set_xlabel('Log2 of Exponent')
ax1.set_ylabel('precompileModExpGas')
ax2.set_ylabel('Size (KB)')
ax1.set_title('3072-bit Key Regression')
ax1.grid(True)
fig.legend(loc='upper right')
plt.savefig('3072_regression.png')
plt.close()

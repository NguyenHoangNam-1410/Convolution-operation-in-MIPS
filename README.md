

# Convolution Operation in MIPS

This project implements a 2D convolution operation using MIPS assembly language. It was developed as an assignment for the Computer Architecture Lab.

## Features

- Reads input image and kernel matrices from a text file.
- Supports floating-point numbers in the format `-xx.xx` or smaller.
- Handles image padding and stride for convolution.
- Outputs the result matrix to a text file, formatted for easy visualization.
- Includes error handling for invalid input formats.

## How It Works

1. **Input Reading:**
	- The program reads the input file specified in the code (`test_7.txt` by default).
	- The first line of the input file should contain four integers: `N M p s`, where:
	  - `N`: Size of the input image (NxN)
	  - `M`: Size of the kernel (MxM)
	  - `p`: Padding size
	  - `s`: Stride value
	- The next `N*N` values are the image matrix (row-major order).
	- The following `M*M` values are the kernel matrix (row-major order).

2. **Processing:**
	- The code parses and stores the image and kernel matrices, handling negative and decimal values.
	- Image padding is applied as specified.
	- The convolution operation is performed using nested loops, applying the kernel to the padded image with the given stride.

3. **Output:**
	- The result matrix is written to `output_matrix.txt`.
	- Each value is formatted with up to four decimal places and padded for alignment.

## Input File Format

Example (`test_7.txt`):

```
3 2 1 1
1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0
0.5 -1.0 2.0 0.0
```

- First line: `N M p s`
- Next `N*N` values: image matrix
- Next `M*M` values: kernel matrix

## Output File Format

The output file (`output_matrix.txt`) contains the result matrix, with each value formatted to four decimal places and columns aligned for readability.

## Error Handling

- If the input file is missing or the format is invalid, the program prints `invalid input` and exits.
- Only floating-point numbers in the format `-xx.xx` or smaller are supported.

## Running the Program

1. Place your input file in the same directory as the MARS MIPS application and this project.
2. Rename the input file to match the filename specified in the code (`test_7.txt` by default).
3. Open `Convolution.asm` in MARS MIPS.
4. Run the program. The output will be saved to `output_matrix.txt`.

## Code Structure

- `.data` section: Defines buffers, filenames, and storage for matrices.
- `.text` section: Implements file reading, parsing, padding, convolution, and output logic.
- Error handling and debugging functions are included for robustness.

## Author

Nguyen Hoang Nam

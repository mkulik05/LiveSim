def remove_empty_lines(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.strip():  # Check if the line is not empty after stripping whitespace
                outfile.write(line)

# Replace 'a.txt' with the actual file path if it's not in the same directory as the script
input_file_path = 'a.txt'
output_file_path = 'a2.txt'

remove_empty_lines(input_file_path, output_file_path)

print(f"Empty lines removed from '{input_file_path}' and saved to '{output_file_path}'.")

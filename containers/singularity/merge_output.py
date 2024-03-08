import os
import sys
import threading

def concatenate_files(output_base_dir):
    temp_filename = os.path.join(output_base_dir, 'temp.txt')
    files = [f for f in os.listdir(output_base_dir) if f.startswith("output_") and f.endswith(".txt")]
    files.sort(key=lambda x: int(x.split('_')[1].split('.')[0]))
    with open(temp_filename, 'w') as temp_file:
        for filename in files:
            with open(os.path.join(output_base_dir, filename), 'r') as file:
                temp_file.write(file.read())

def main(directory):
    output_final_dir = os.path.join(directory, 'output_final')
    base_dirs = [d for d in os.listdir(output_final_dir) if os.path.isdir(os.path.join(output_final_dir, d))]

    threads = []
    for base_dir in base_dirs:
        thread = threading.Thread(target=concatenate_files, args=(os.path.join(output_final_dir, base_dir),))
        thread.start()
        threads.append(thread)

    for thread in threads:
        thread.join()

    temp_files = [os.path.join(output_final_dir, base_dir, 'temp.txt') for base_dir in base_dirs]
    temp_files.sort()

    with open('output_all.txt', 'w') as final_file:
        for temp_file in temp_files:
            with open(temp_file, 'r') as file:
                final_file.write(file.read())

    # Clean up temporary files
    for temp_file in temp_files:
        os.remove(temp_file)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python merge_output.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    main(directory)

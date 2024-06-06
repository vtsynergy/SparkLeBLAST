import random
from Bio import SeqIO

def select_random_sequences(input_fasta, output_fasta, num_sequences=50):
    # Read the sequences from the input FASTA file
    sequences = list(SeqIO.parse(input_fasta, "fasta"))
    
    # Get the number of sequences in the original file
    num_original_sequences = len(sequences)
    
    # Print the number of sequences in the original file
    print(f"Number of sequences in the original file: {num_original_sequences}")
    
    # Check if the number of sequences in the file is less than the desired number
    if num_original_sequences < num_sequences:
        raise ValueError(f"The input FASTA file contains only {num_original_sequences} sequences, which is less than the requested {num_sequences} sequences.")
    
    # Randomly select the desired number of sequences
    selected_sequences = random.sample(sequences, num_sequences)
    
    # Write the selected sequences to the output FASTA file
    SeqIO.write(selected_sequences, output_fasta, "fasta")
    
    # Get the number of sequences in the new file
    num_selected_sequences = len(selected_sequences)
    
    # Print the number of sequences in the new file
    print(f"Number of sequences in the new file: {num_selected_sequences}")

# Example usage
input_fasta = "non-rRNA-reads.fa"
output_fasta = "non-rRNA-reads_sample50.fa"
select_random_sequences(input_fasta, output_fasta, num_sequences=50)


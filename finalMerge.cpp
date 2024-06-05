#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <algorithm>
#include <cstdlib>

namespace fs = std::filesystem;

void mergeFiles(const std::string &inputDir, const std::string &outputFile) {
    std::vector<std::string> partFiles;

    for (const auto &entry : fs::directory_iterator(inputDir)) {
        std::string fileName = entry.path().filename().string();
        if (fileName.find("part-") == 0) {
            partFiles.push_back(entry.path().string());
        }
    }

    std::sort(partFiles.begin(), partFiles.end());

    std::string command = "cat ";
    for (const auto &partFile : partFiles) {
        command += partFile + " ";
    }
    command += "> " + outputFile;

    int result = std::system(command.c_str());
    if (result != 0) {
        std::cerr << "Error: Failed to merge files using command: " << command << std::endl;
    } else {
        std::cout << "Files merged successfully into " << outputFile << std::endl;
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <input_directory> <output_file>" << std::endl;
        return 1;
    }

    std::string inputDir = argv[1];
    std::string outputFile = argv[2];

    mergeFiles(inputDir, outputFile);

    return 0;
}

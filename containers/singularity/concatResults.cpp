#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>
#include <regex>
#include <algorithm>

namespace fs = std::filesystem;

std::string preprocessLine(const std::string& line) {
    std::string processed = line.substr(1, line.size() - 2);
    size_t commaPos = processed.find_last_of(',');
    if (commaPos != std::string::npos) {
        processed = processed.substr(0, commaPos);
    }

    return processed;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <input_directory> <output_file>" << std::endl;
        return 1;
    }

    std::string directoryPath = argv[1];
    std::string outputFile = argv[2];

    std::vector<std::string> fileNames;
    for (const auto& entry : fs::directory_iterator(directoryPath)) {
        if (entry.path().filename().string().find("part-") == 0) {
            fileNames.push_back(entry.path().string());
        }
    }

    std::sort(fileNames.begin(), fileNames.end());

    std::ofstream outFile(outputFile);
    if (!outFile.is_open()) {
        std::cerr << "Failed to open output file: " << outputFile << std::endl;
        return 1;
    }

    for (const std::string& fileName : fileNames) {
        std::ifstream inFile(fileName);
        if (!inFile.is_open()) {
            std::cerr << "Failed to open input file: " << fileName << std::endl;
            return 1;
        }

        std::string line;
        while (std::getline(inFile, line)) {
            outFile << preprocessLine(line) << std::endl;
        }
    }

    outFile.close();
    std::cout << "Merging completed. Output file: " << outputFile << std::endl;

    return 0;
}


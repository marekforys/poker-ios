extension Array {
    func combinations(of size: Int) -> [[Element]] {
        guard count >= size else { return [] }
        guard size > 0 else { return [[]] }
        
        if size == 0 {
            return [self]
        }
        
        if size == 1 {
            return map { [$0] }
        }
        
        guard let first = self.first else { return [] }
        let subArray = Array(self.dropFirst())
        
        // Combinations that include the first element
        let subCombinations = subArray.combinations(of: size - 1)
        var result = subCombinations.map { [first] + $0 }
        
        // Combinations that don't include the first element
        result += subArray.combinations(of: size)
        
        return result
    }
}

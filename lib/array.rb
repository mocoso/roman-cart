class Array
  def pad(size, filler)
    while self.size < size
      self << filler
    end
  end
end

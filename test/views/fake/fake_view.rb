module ViewMapper
  module FakeView
    def self.source_root
      File.expand_path(File.dirname(__FILE__) + '/templates')
    end
  end
end

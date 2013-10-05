class FakeModel2 < FakeModel

  deftype :pizza, 'Pizza' do
    def run
      :pizza
    end
  end

  type_alias :pizza, :sauce
end

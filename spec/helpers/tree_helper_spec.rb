require 'spec_helper'

describe TreeHelper do
  describe 'flatten_tree' do
    let(:project) { create(:project, :repository) }

    before do
      @repository = project.repository
      @commit = project.commit("e56497bb")
    end

    context "on a directory containing more than one file/directory" do
      let(:tree_item) { double(name: "files", path: "files") }

      it "returns the directory name" do
        expect(flatten_tree(tree_item)).to match('files')
      end
    end

    context "on a directory containing only one directory" do
      let(:tree_item) { double(name: "foo", path: "foo") }

      it "returns the flattened path" do
        expect(flatten_tree(tree_item)).to match('foo/bar')
      end
    end
  end
end

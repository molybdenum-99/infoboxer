module Infoboxer
  describe Navigation::Wikipath do
    include Saharspec::Util

    let(:document) {
      Parser.document(multiline(%{
        |Test in first ''paragraph''
        |
        | {{Use dmy dates|date=July 2014}}
        |
        |=== Section 1 ===
        |
        |{| some=table
        ||With
        |* cool list
        |* ''And'' deep test
        |* some more
        ||}
        |
        | {{template}}
      }))
    }

    subject { ->(path) { document.wikipath(path) } }

    its(['//template']) { is_expected.to be_a(Tree::Nodes).and all be_a(Tree::Template) }
    its(['//template']) { is_expected.not_to be_empty }
    its(['//table//list//italic']) { is_expected.to have_attributes(text: 'And') }
    its(['//template[name=/^Use/]']) {
      is_expected
        .to include(have_attributes(name: 'Use dmy dates'))
        .and not_include(have_attributes(name: 'template'))
    }
    its(['//table//list/list_item[first]']) {
      is_expected
        .to include(have_attributes(text_: '* cool list'))
        .and not_include(have_attributes(text_: '* some more'))
    }
    its(['//template/var[name=date]']) { is_expected.to include(be_a(Tree::Var).and(have_attributes(name: 'date'))) }
    its(['/section']) { is_expected.not_to be_empty }
    its(['/section[heading=Section 1]']) { is_expected.to eq [document.sections.first] }
  end
end

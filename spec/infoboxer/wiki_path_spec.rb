# encoding: utf-8
require 'infoboxer/wiki_path'

module Infoboxer
  describe WikiPath do
    describe '._parse' do
      subject { ->(source) { described_class._parse(source) } } #.to_h } }

      context 'one level' do
        its(['/template']) { is_expected.to eq [{type: :Template}] }
        its(['/template[name=Infobox]']) { is_expected.to eq [{type: :Template, name: 'Infobox'}] }
        its(['/template[name="Infobox"]']) { is_expected.to eq [{type: :Template, name: 'Infobox'}] }
        its(['/template[name=/^Infobox/]']) { is_expected.to eq [{type: :Template, name: /^Infobox/}] }
        its(['/template[name="Infobox"][index=1]']) { is_expected.to eq [{type: :Template, name: 'Infobox', index: '1'}] }
        its(['/[italic]']) { is_expected.to eq [{predicates: %i[italic?]}] }
        its(['/[italic][first]']) { is_expected.to eq [{predicates: %i[italic? first?]}] }
      end

      context 'several levels' do
        its(['/template[name=Infobox]/var[name=1]']) {
          is_expected.to eq [{type: :Template, name: 'Infobox'}, {type: :Var, name: '1'}]
        }
      end

      xcontext 'wildcards' do
        its(['/*']) { is_expected.to eq [{type: %r{.+}}] }
      end

      context 'skiplevels' do
        its(['//template']) { is_expected.to eq [{type: :Template, op: :lookup}] }
      end

      context 'erroneous paths' do
        it {expect { subject['foo'] }.to raise_error(WikiPath::ParseError, %r{expecting /}) }
      end
    end

    describe '#call' do
      let(:node) { spy }
      subject { ->(source) { described_class.parse(source).call(node) } }

      context 'one level' do
        its(['/template']) {
          is_expected.to send_message(node, :lookup_children).with(:Template)
        }
        its(['/template[name=Infobox]']) {
          is_expected.to send_message(node, :lookup_children).with(:Template, name: 'Infobox')
        }
        its(['/template[name=/^Infobox/]']) {
          is_expected.to send_message(node, :lookup_children).with(:Template, name: /^Infobox/)
        }
        its(['/template[name=/^Infobox/][first]']) {
          is_expected.to send_message(node, :lookup_children).with(:Template, :first?, name: /^Infobox/)
        }
      end

      xcontext 'several levels' do
        its(['/template[name=Infobox]/var[name=1]']) {
          is_expected.to \
            send_message(node, :lookup_children).with(:Template, name: 'Infobox')
            .and_then(:lookup_children).with(:Var, name: '1')
        }
      end

      xcontext 'skiplevels' do
        its(['//template/var[name=1]//wikilink']) {
          is_expected.to \
            send_message(node, :lookup).with(:Template)
            .and_then(:lookup_children).with(:Var, name: '1')
            .and_then(:lookup).with(:Wikilink)

        }
      end
    end
  end
end

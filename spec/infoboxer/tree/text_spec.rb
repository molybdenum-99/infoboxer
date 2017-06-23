# encoding: utf-8

module Infoboxer
  module Tree
    describe Node do
      describe :text do
        context 'from node' do
          let(:text) { node.text }
          subject { text }

          context Text do
            let(:node) { Text.new('test') }

            it { is_expected.to eq 'test' }
          end

          context Compound do
            let(:node) { Compound.new([Text.new('one'), Text.new('two')]) }

            it { is_expected.to eq 'onetwo' }
          end

          context Paragraph do
            let(:node) { Paragraph.new([Text.new('one')]) }

            it { is_expected.to eq "one\n\n" }
          end
        end

        context 'from source' do
          let(:document) { Parser.document(unindent(source)) }
          let(:text) { document.text }
          subject { text }

          context 'simple headings and paragraphs' do
            let(:source) {
              %{
              == Heading 2 ==
              === Heading 3 ===
              Paragraph.

              Other paragraph.
              Still that, other paragraph.
            }}

            it {
              is_expected.to eq \
                "Heading 2\n\n" \
                "Heading 3\n\n" \
                "Paragraph.\n\n" \
                "Other paragraph. Still that, other paragraph.\n\n"
            }
          end

          context 'lists' do
            context 'unordered' do
              let(:source) {
                %{
                * its
                * a
                * list
              }}

              it {
                is_expected.to eq \
                  "* its\n"\
                  "* a\n"\
                  "* list\n\n"
              }
            end

            context 'ordered' do
              let(:source) {
                %{
                # its
                # a
                # list
              }}

              it {
                is_expected.to eq \
                  "1. its\n"\
                  "2. a\n"\
                  "3. list\n\n"
              }
            end

            context 'definitions' do
              let(:source) {
                %{
                ; its
                : a
                ; list
                : of defs
              }}

              it {
                is_expected.to eq \
                  "its:\n"\
                  "  a\n"\
                  "list:\n"\
                  "  of defs\n\n"
              }
            end

            context 'nest' do
              let(:source) {
                %{
                * its
                ** a
                ** nested
                * list
              }}

              it {
                is_expected.to eq \
                  "* its\n"\
                  "  * a\n"\
                  "  * nested\n"\
                  "* list\n\n"\
              }
            end

            context 'mixing and nesting' do
              let(:source) {
                %{
                * list
                * with
                *# different
                *# levels of
                *#; deep
                *#: inlining!
                * is cool

                paragraph
              }}

              it {
                is_expected.to eq \
                  "* list\n" \
                  "* with\n" \
                  "  1. different\n" \
                  "  2. levels of\n" \
                  "    deep:\n" \
                  "      inlining!\n" \
                  "* is cool\n\n"\
                  "paragraph\n\n"
              }
            end
          end

          context 'pre' do
            let(:source) {
              %{
              Here will be pre:

               First line
               Next line
              }}

            it {
              is_expected.to eq \
                "Here will be pre:\n\n" \
                "First line\n" \
                "Next line\n\n"
            }
          end

          context 'tables' do
            let(:source) {
              %{
              {|
              |+ Caption
              |-
              ! first
              ! row
              ! headings
              |-
              | next
              | row
              | cells
              |-
              | even
              | next
              | row
              |}
            }}

            it {
              is_expected.to eq \
                "+-------+------+----------+\n"\
                "|         Caption         |\n"\
                "+-------+------+----------+\n"\
                "| first | row  | headings |\n"\
                "+-------+------+----------+\n"\
                "| next  | row  | cells    |\n"\
                "| even  | next | row      |\n"\
                "+-------+------+----------+\n\n"
            }
          end

          context 'links and other inline markup' do
            let(:source) { "one ''two'' [[named|link]] [[unnamed link]]" }
            it { is_expected.to eq "one two link unnamed link\n\n" }
          end

          context 'br' do
            let(:source) { 'one<br/>two' }
            it { is_expected.to eq "one\ntwo\n\n" }
          end

          context 'ref' do
            let(:source) { 'some text<ref>with ref</ref>' }
            it { is_expected.to eq "some text\n\n" }
          end

          context 'templates' do
            let(:source) { "some text{{with|realy=complex ''template''}}" }
            it { is_expected.to eq "some text\n\n" }
          end

          context 'html tags' do
            let(:source) { 'some text <b>with bold</b> text' }
            it { is_expected.to eq "some text with bold text\n\n" }
          end

          context 'math' do
            let(:source) { '<math>g = \frac{F}{m} = \frac {G M_T}{{R_T}^2} </math>' }
            it { is_expected.to eq "<math>g = \\frac{F}{m} = \\frac {G M_T}{{R_T}^2} </math>\n\n" }
          end
        end
      end
    end
  end
end

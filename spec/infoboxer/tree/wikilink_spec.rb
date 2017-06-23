# encoding: utf-8

module Infoboxer
  module Tree
    describe Wikilink do
      describe 'plain vanilla' do
        subject { Wikilink.new('Test') }
        its(:name) { is_expected.to eq 'Test' }
        its(:namespace) { is_expected.to eq '' }
        its(:anchor) { is_expected.to eq '' }
        its(:topic) { is_expected.to eq 'Test' }
        its(:refinement) { is_expected.to eq '' }
      end

      context :namespace do
        subject { Wikilink.new('Category:Test') }
        its(:name) { is_expected.to eq 'Test' }
        its(:namespace) { is_expected.to eq 'Category' }

        # TODO: check how Wikipedia thinks about it, internally!
        context 'when deeper' do
        end
      end

      context :anchor do
        subject { Wikilink.new('Test#Yourself') }
        its(:name) { is_expected.to eq 'Test' }
        its(:anchor) { is_expected.to eq 'Yourself' }
      end

      context :topic do
        context ',' do
          subject { Wikilink.new('Phoenix, Arizona') }
          its(:topic) { is_expected.to eq 'Phoenix' }
          its(:refinement) { is_expected.to eq 'Arizona' }

          context 'when several commas' do
            subject { Wikilink.new('Phoenix, Arizona, USA') }
            its(:topic) { is_expected.to eq 'Phoenix' }
            its(:refinement) { is_expected.to eq 'Arizona, USA' }
          end
        end

        context '()' do
          subject { Wikilink.new('Pipe (computing)') }
          its(:topic) { is_expected.to eq 'Pipe' }
          its(:refinement) { is_expected.to eq 'computing' }
        end

        context ', ()' do
          subject { Wikilink.new('Phoenix, Arizona (USA)') }
          its(:topic) { is_expected.to eq 'Phoenix, Arizona' }
          its(:refinement) { is_expected.to eq 'USA' }
        end
      end

      describe 'everything at once!' do
        subject { Wikilink.new('Talk:Me, myself and Irene (film, bad)#Reception') }
        its(:name) { is_expected.to eq 'Me, myself and Irene (film, bad)' }
        its(:namespace) { is_expected.to eq 'Talk' }
        its(:anchor) { is_expected.to eq 'Reception' }
        its(:topic) { is_expected.to eq 'Me, myself and Irene' }
        its(:refinement) { is_expected.to eq 'film, bad' }
      end

      describe 'pipe trick' do
        subject { Wikilink.new('Phoenix, Arizona', Text.new('')) }
        its(:children) { is_expected.to eq [Text.new('Phoenix')] }
      end
    end
  end
end

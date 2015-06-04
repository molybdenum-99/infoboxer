# encoding: utf-8
module Infoboxer
  describe Parse do
    describe :document do
      subject{Parse.document('just text')}

      it{should be_a(Document)}
    end
  end
end

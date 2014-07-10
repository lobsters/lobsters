describe StoriesPaginator do
  let(:current_user) { User.make! }
  let(:paginator)    { described_class.new(scope, 1, current_user) }

  describe '.page' do
    context 'fake scope' do
      let(:scope) { double('Stories Scope').as_null_object }

      before do
        allow(scope).to receive(:to_a) { scope }
        expect(scope).to receive(:limit).with(26) { scope }
        expect(scope).to receive(:offset).with(0) { scope }
        Vote.stub :votes_by_user_for_stories_hash
      end

      it 'paginates given scope' do
        paginator.stub :result
        paginator.get
      end

      describe 'show more' do
        subject { stories.hottest[1] }

        it 'is true if scope.count > 25' do
          allow(scope).to receive(:count).and_return 26
          expect(paginator.get[1]).to eq true
        end

        it 'is false if scope.count <= 25' do
          allow(scope).to receive(:count).and_return 10
          expect(paginator.get[1]).to eq false
        end
      end
    end

    context 'integration' do
      let!(:s1) { Story.make! }
      let!(:s2) { Story.make! }
      let!(:s3) { Story.make! }

      let!(:v1) { Vote.make! story: s1, user: current_user }
      let!(:v2) { Vote.make! story: s2 }

      let(:scope) { Story.all }

      it 'saves if user have voted for the post' do
        result = paginator.get[0]
        expect(result.find { |s| s.id == s1.id }.vote).to eq 1
        expect(result.find { |s| s.id == s2.id }.vote).to be_nil
        expect(result.find { |s| s.id == s3.id }.vote).to be_nil
      end
    end
  end
end

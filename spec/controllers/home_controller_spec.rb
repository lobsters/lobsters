describe HomeController do
  before { Rails.cache.clear }
  before {
    unless example.metadata[:skip_before]
      StoriesPaginator.any_instance.should_receive(:get).and_return [scope, true]
    end
  }

  describe 'GET index' do
    let(:scope) { double 'Hottest Scope' }

    before { StoryRepository.any_instance.should_receive(:hottest) }    
    before { get :index }

    context 'assigns' do
      describe 'rss_link' do
        subject { assigns(:rss_link) }

        its([:title]) { should eq 'RSS 2.0' }
        its([:href]) { should include '/rss' }
      end

      describe 'page' do
        subject { assigns(:page) }

        it { should eq 1 }
      end

      describe 'stories' do
        subject { assigns(:stories) }

        it { should eq scope }
      end

      describe 'show_more' do
        subject { assigns(:show_more) }

        it { should eq true }
      end
    end
  end

  describe 'GET index' do
    let(:scope) { double 'Hidden Scope' }

    before { StoryRepository.any_instance.should_receive(:hidden) }
    before { get :hidden }

    context 'assigns' do
      describe 'stories' do
        subject { assigns(:stories) }

        it { should eq scope }
      end
    end
  end

  describe 'GET newest' do
    let(:scope) { double 'Newest Scope' }

    before { StoryRepository.any_instance.should_receive(:newest) }
    before { get :newest }

    context 'assigns' do
      describe 'stories' do
        subject { assigns(:stories) }

        it { should eq scope }
      end
    end
  end

  describe 'GET newest_by_user' do
    let(:scope) { double 'Newest By User Scope' }
    let(:user) { User.make! }

    before { StoryRepository.any_instance.should_receive(:newest_by_user).with(user) }
    before { get 'newest_by_user', user: user.username }

    context 'assigns' do
      describe 'stories' do
        subject { assigns(:stories) }

        it { should eq scope }
      end
    end
  end

  describe 'GET recent' do
    let(:scope) { double 'Recent Scope' }

    before { StoryRepository.any_instance.should_receive(:recent) }
    before { get 'recent' }

    context 'assigns' do
      describe 'stories' do
        subject { assigns(:stories) }

        it { should eq scope }
      end
    end
  end

  describe 'GET tagged' do
    let(:scope) { double 'Tagged Scope' }
    let(:tag) { Tag.make! tag: 'tag' }

    before { StoryRepository.any_instance.should_receive(:tagged).with(tag) }
    before { get 'tagged', tag: tag.tag }

    context 'assigns' do
      describe 'stories' do
        subject { assigns(:stories) }

        it { should eq scope }
      end
    end
  end

  describe 'GET top' do
    let(:scope) { double 'Top Scope' }

    before { StoryRepository.any_instance.should_receive(:top) }
    before { get 'top' }

    context 'assigns' do
      describe 'stories' do
        subject { assigns(:stories) }

        it { should eq scope }
      end
    end
  end

  describe 'GET upvoted', skip_before: true do
    before { get 'upvoted' }
    it { should redirect_to(login_path) }
  end
end

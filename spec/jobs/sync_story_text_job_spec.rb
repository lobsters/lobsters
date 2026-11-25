require "rails_helper"

describe SyncStoryTextJob do
  it "is enqueued when a story is created" do
    expect { create(:story) }.to have_enqueued_job(SyncStoryTextJob)
  end

  it "is enqueued when title or description changes" do
    story = create(:story)
    expect { story.update!(title: "new title here", editor: story.user) }.to have_enqueued_job(SyncStoryTextJob)
    expect { story.update!(is_moderated: true) }.not_to have_enqueued_job(SyncStoryTextJob)
  end

  it "fetches story texts" do
    story = create(:story, title: "Mxyzptlk")
    expect(Diffbot).to receive(:get_story_text).once.and_return("Gsptlsnz text")
    2.times { SyncStoryTextJob.perform_now(story) }
    expect(story.reload.story_text.body).to eq "Gsptlsnz text"
    expect(Story.search("Mxyzptlk")).to include(story)
    expect(Story.search("Gsptlsnz")).to include(story)
  end

  it "syncs title changes" do
    story = create(:story, title: "Mxyzptlk")
    SyncStoryTextJob.perform_now(story)
    expect(Story.search("Mxyzptlk")).to include(story)
    expect(Story.search("Gsptlsnz")).to_not include(story)

    story.update!(title: "Gsptlsnz", editor: story.user)
    SyncStoryTextJob.perform_now(story)
    expect(Story.search("Mxyzptlk")).to_not include(story)
    expect(Story.search("Gsptlsnz")).to include(story)
  end
end

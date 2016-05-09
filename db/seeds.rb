User.create({ username: "nickhould", 
              email: "nick.hould@gmail.com", 
              password: "testtest", 
              password_confirmation: "testtest",
              is_admin: true, 
              is_moderator: true})
user = User.first

tags = [{ tag: "statistics" },
        { tag: "dataset" },
        { tag: "sql" },
        { tag: "machine learning" },
        { tag: "podcast" },
        { tag: "data science" },
        { tag: "probability" },
        { tag: "algorithms" },
        { tag: "jupyter notebook" },
        { tag: "python" },
        { tag: "bayes" }
       ]

if Tag.create(tags)
  puts "Created #{tags.count} tags."
end 

stories = [
  {
    user_id: user.id,
    url: "http://allendowney.blogspot.ca/2016/04/bayes-on-jupyter.html",
    title: "Bayes on Jupyter",
    tags_a: ["statistics"]
  }, {
    user_id: user.id,
    url: "https://medium.com/@michael.fire/reddatait-analyzing-over-a-tb-of-reddit-comments-to-construct-the-largest-publicly-available-83f2c234f5fd",
    title: "Reddatait - The largest publicly available social network evolution dataset",
    tags_a: ["dataset"]
  }, {
    user_id: user.id,
    url: "http://patshaughnessy.net/2015/11/24/a-look-at-how-postgres-executes-a-tiny-join",
    title: "A Look at How Postgres Executes a Tiny Join",
    tags_a: ["sql"]
  }, {
    user_id: user.id,
    url: "http://machinelearningmastery.com/machine-learning-algorithms-mini-course/",
    title: "Machine Learning Algorithms Mini-Course",
    tags_a: ["machine learning"]
  }, {
    user_id: user.id,
    url: "http://101.datascience.community/2016/04/21/tips-for-future-data-scientists/",
    title: "Tips for future data scientists",
    tags_a: ["data science career"]
  }, {
    user_id: user.id,
    url: "https://www.oreilly.com/ideas/machines-that-dream",
    title: "Machines that dream",
    tags_a: ["machine learning"]
  }, {
    user_id: user.id,
    url: "http://www.becomingadatascientist.com/2016/04/11/becoming-a-data-scientist-episode-09-justin-kiggins/",
    title: "Interview with Justin Kiggins",
    tags_a: ["podcast"]
  }, {
    user_id: user.id,
    url: "https://peadarcoyle.wordpress.com/2015/08/17/interviews-with-a-data-scientist-cameron-davidson-pilon/",
    title: "Interviews with a data scientist: Cameron Davidson-Pilon",
    tags_a: ["podcast"]
  }, {
    user_id: user.id,
    url: "http://machinelearningmastery.com/naive-bayes-for-machine-learning/",
    title: "Naive Bayes for Machine Learning",
    tags_a: ["statistics"]
  }, {
    user_id: user.id,
    url: "https://kbroman.wordpress.com/2016/04/08/i-am-a-data-scientist/",
    title: "I am a data scientist",
    tags_a: ["data science"]
  }, {
    user_id: user.id,
    url: "http://jliszka.github.io/2016/04/05/probability-is-in-the-process.html",
    title: "Probability is in the process",
    tags_a: ["probability"]
  }, {
    user_id: user.id,
    url: "http://datascopeanalytics.com/static/pieces/2016/designing-and-teaching-a-data-science-bootcamp/metis_case_study.pdf",
    title: "Designing and Teaching a Data Science Bootcamp",
    tags_a: ["data science bootcamp"]
  },  {
    user_id: user.id,
    url: "http://rpubs.com/JDAHAN/172473",
    title: "Data Science Interview Questions & Detailed Answers",
    tags_a: ["data science bootcamp"]
  },  {
    user_id: user.id,
    url: "http://www.kdnuggets.com/2016/04/unbalanced-classes-svm-random-forests-python.html",
    title: "Dealing with Unbalanced Classes, SVMs, Random Forests, and Decision Trees in Python",
    tags_a: ["machine learning", "algorithms"]
  }, {
    user_id: user.id,
    url: "http://www.kdnuggets.com/2016/04/unbalanced-classes-svm-random-forests-python.html",
    title: "Dealing with Unbalanced Classes, SVMs, Random Forests, and Decision Trees in Python",
    tags_a: ["machine learning", "algorithms"]
  },  {
    user_id: user.id,
    url: "http://blog.jupyter.org/2016/04/15/notebook-4-2/",
    title: "Jupyter Notebook 4.2",
    tags_a: ["jupyter notebook", "python"]
  }, {
    user_id: user.id,
    url: "http://computationallegalstudies.com/2016/03/31/bayesdb-data-science-is-a-communication-problem-via-oreilly/ ",
    title: "BayesDB: Data Science is a Communication Problem (via OReilly",
    tags_a: ["statistics", "bayes"]
  }, {
    user_id: user.id,
    url: "http://notstatschat.tumblr.com/post/142811881871",
    title: "Size Matters",
    tags_a: ["machine learning"]
  }, {
    user_id: user.id,
    url: "https://www.reddit.com/r/datascience/comments/4h3nky/plan_to_become_a_junior_data_scientist_is_it/",
    title: "Plan to become a junior data scientist - is it realistic",
    tags_a: ["data science"]
  }, {
    user_id: user.id,
    url: "http://duelingdata.blogspot.ca/2016/04/game-of-thrones-analysis.html",
    title: "Game of Thrones Analysis",
    tags_a: ["data science"]
  }, {
    user_id: user.id,
    url: "http://www.reddit.com/r/MachineLearning/comments/4h385f/how_do_you_find_machine_learning/",
    title: "How do you find machine learning conventions/meetups/etc close to you?",
    tags_a: ["machine learning"]
  }, {
    user_id: user.id,
    url: "http://www.erogol.com/1301-2/",
    title: "How Many Training Samples We Observe Over Life Time?",
    tags_a: ["statistics"]
  }, {
    user_id: user.id,
    url: "https://www.youtube.com/watch?v=u3JJsoBpRYk",
    title: "A Hitchhiker's Guide to Data Science",
    tags_a: ["statistics", "data science"]
  }, {
    user_id: user.id,
    url: "https://www.youtube.com/watch?v=o0EacbIbf58",
    title: "The Future of NumPy Indexing",
    tags_a: ["statistics"]
  }, {
    user_id: user.id,
    url: "https://www.youtube.com/watch?v=mtIePLVqVhA",
    title: "Understanding Random Forests",
    tags_a: ["statistics"]
  }, {
    user_id: user.id,
    url: "https://www.youtube.com/watch?v=Nppjvghc2NY",
    title: "The solution of inverse problems",
    tags_a: ["statistics"]
  }
]

if Story.create(stories)
  puts "Created #{stories.count} stories"
end


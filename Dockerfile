FROM lambci/lambda:build-ruby2.5

# Install node (which is not available as standard on ym
RUN yum install -y gcc-c++ make
RUN curl -sL https://rpm.nodesource.com/setup_6.x | sh -
RUN yum install -y nodejs

RUN npm install -g try-thread-sleep
RUN npm install -g serverless --ignore-scripts spawn-sync

# Configure the main working directory. This is the base 
# directory used in any further RUN, COPY, and ENTRYPOINT 
# commands.
RUN mkdir -p /app
WORKDIR /app

# Copy the Gemfile as well as the Gemfile.lock and install 
# the RubyGems. This is a separate step so the dependencies 
# will be cached unless changes to one of those two files 
# are made.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 20 --retry 5

# Link AWS configuration to home directory
RUN ln -s /app/.aws ~/.aws 

# Copy the main application.
COPY . ./

# The main command to run when the container starts. Also 
# tell the Rails dev server to bind to all interfaces by 
# default.
CMD ["bundle", "exec", "thin", "start", "-R", "config.ru", "-p", "3043"]

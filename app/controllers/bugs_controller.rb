class BugsController < ApplicationController
  include ApplicationHelper

  # when using dalayed jobs, detecting errors will be situational that's why this method will always return success, however the record won't be saved if there're any errors
  def create
    @bug = Bug.new(bug_params)
    @bug.application_token = request.headers["application-token"]
    @bug.number = Bug.next_bug_number(@bug.application_token)
    @state = State.new(state_params)

    queue = get_bunny_channel.queue("bug", auto_delete: true)

    queue.subscribe do |delivery_info, properties, payload|
      ActiveRecord::Base.transaction do
        bug, state = JSON.parse(payload)
        Bug.create!(bug)
        State.create!(state)
      end
    end

    queue.publish([@bug, @state].to_json, :routing_key => queue.name)

    render action: '/create/success', status: :ok
  end

  def count
    if request.headers.key?("application-token")
      application_token = request.headers["application-token"]
      @count = Bug.get_bug_number_count(application_token)
      render action: '/count/success', status: :ok
    else
      render action: '/count/error', status: :unprocessable_entity
    end
  end

  def show
    application_token = request.headers["application-token"]
    bug_number = params[:number]
    @bug = Bug.where("application_token = ? AND number = ?", application_token, bug_number)[0]
    if @bug
      render action: '/show/success', status: :ok
    else
      render action: '/show/error', status: :unprocessable_entity
    end
  end

  private

  def bug_params
    params.require(:bug).permit(:status, :priority, :comment)
  end

  def state_params
    params.require(:state).permit(:device, :os, :storage, :memory)
  end
end

require 'rails_helper'
require 'spec_helper'

describe BugsController do
  render_views
  describe "post #create" do

    it "return success" do
      @request.headers["application-token"] = "wdas222kzzzxx"
      post :create,
        bug: { priority: "minor", status: "new", comment: "hamada"},
        state: { os: "android", device: "samsung", storage: "2012", memory: "225" },
        format: :json

      expect(response.status).to eq(200)
    end

    it "doesn't create new bug when there's error" do
      @request.headers["application-token"] = "wdas222kzzzxx"
      expect{
        post :create,
        bug: { priority: "minor" },
        state: { os: "android", device: "samsung", storage: "2012", memory: "225" },
        format: :json
      }.to change(Bug, :count).by(0)
    end

  end

  describe "get #count" do

    it "return correct count number" do
      @request.headers["application-token"] = "wdas222kzzzxx"
      get :count, format: :json
      actual_count = Bug.where("application_token = ?", @request.headers["application-token"]).count
      expect(JSON.parse(@response.body)["count"]).to eq(actual_count)
    end

    it "return error when application-token is missing" do
      get :count, format: :json
      expect(response.status).to eq(422)
    end

  end

  describe "get #show" do

    it "return correct bug" do
      bug_number = Bug.last.number
      @request.headers["application-token"] = "wdas222kzzzxx"
      get :show, format: :json, number: bug_number
      actual_bug = Bug.where("application_token = ? AND number = ?", @request.headers["application-token"], bug_number)[0]
      expect(JSON.parse(actual_bug.to_json)).to eq(JSON.parse(@response.body)["bug"])
    end

    it "return error when bug is not exist" do
      bug_number = "e22x"
      @request.headers["application-token"] = "wdas222kzzzxx"
      get :show, format: :json, number: bug_number
      expect(response.status).to eq(422)
    end

  end

end

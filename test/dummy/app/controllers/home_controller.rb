class HomeController < ApplicationController
  def index
    @val = Bullring.run("Math.random()")
  end
end

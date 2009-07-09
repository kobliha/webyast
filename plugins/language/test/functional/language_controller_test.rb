require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class LanguageControllerTest < ActionController::TestCase
  fixtures :accounts
  
  def setup
    @model_class = Language
    @controller = LanguageController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA
  end

  include PluginBasicTests

  DATA = {:language => {
      :current => "cs_CZ",
      :utf8 => "true",
      :rootlocale => "false"
    }}

  def test_update   
    Language.any_instance.stubs(:save)
    put :update, DATA
    check_update_result
  end

  def test_create
    Language.any_instance.stubs(:save)
    put :create, DATA
    check_update_result
  end

  def check_update_result
    assert_response :success
    lang = assigns(:language)
    assert lang
    assert_equal lang.language, DATA[:language][:current]
    assert_equal lang.utf8, DATA[:language][:utf8]
    assert_equal lang.rootlocale, DATA[:language][:rootlocale]
  end
end

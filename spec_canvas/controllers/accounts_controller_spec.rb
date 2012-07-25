#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of the analytics engine

require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe AccountsController, :type => :controller do
  ROLE = 'TestAdmin'

  before :each do
    @account = Account.default
    @account.allowed_services = '+analytics'
    @account.save!

    RoleOverride.manage_role_override(@account, ROLE, 'read_course_list', :override => true)
    RoleOverride.manage_role_override(@account, ROLE, 'view_analytics', :override => true)

    @admin = account_admin_user(:account => @account, :membership_type => ROLE, :active_all => true)
    user_session(@admin)
  end

  context "permissions" do
    def expect_injection
      call_parameters = []
      AccountsController.any_instance.expects(:js_env).at_least_once.with{ |*parameters| call_parameters << parameters }
      get 'show', :id => @account.id, :format => 'html'
      call_parameters.should include([{:ANALYTICS => { :link => "/accounts/#{@account.id}/analytics" }}])
    end

    def forbid_injection
      call_parameters = []
      AccountsController.any_instance.expects(:js_env).at_least(0).yields{ |*parameters| call_parameters << parameters }
      get 'show', :id => @account.id, :format => 'html'
      call_parameters.should_not include([{:ANALYTICS => { :link => "/accounts/#{@account.id}/analytics" }}])
    end

    it "should inject an analytics button on the account page under nominal conditions" do
      expect_injection
    end

    it "should not inject an analytics button on the account page when analytics is disabled" do
      @account.allowed_services = '-analytics'
      @account.save!
      forbid_injection
    end

    it "should not inject an analytics button on the account page without the analytics permission" do
      RoleOverride.manage_role_override(@account, ROLE, 'view_analytics', :override => false)
      forbid_injection
    end
  end
end
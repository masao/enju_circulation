# -*- encoding: utf-8 -*-
class ReservesController < ApplicationController
  before_filter :store_location, :only => :index
  load_and_authorize_resource :except => :index
  authorize_resource :only => :index
  before_filter :get_user_if_nil
  #, :only => [:show, :edit, :create, :update, :destroy]
  helper_method :get_manifestation
  helper_method :get_item
  before_filter :store_page, :only => :index

  # GET /reserves
  # GET /reserves.json
  def index
    unless current_user.has_role?('Librarian')
      if @user
        unless current_user == @user
          access_denied; return
        end
      else
        redirect_to user_reserves_path(current_user)
        return
      end
    end

    if params[:mode] == 'hold' and current_user.has_role?('Librarian')
      @reserves = Reserve.hold.order('reserves.id DESC').page(params[:page])
    else
      if @user
        # 一般ユーザ
        @reserves = @user.reserves.order('reserves.id DESC').page(params[:page])
      else
        # 管理者
        @reserves = Reserve.order('reserves.id DESC').includes(:manifestation).page(params[:page])
      end
    end

    respond_to do |format|
      format.html # index.rhtml
      format.json { render :json => @reserves.to_json }
      format.rss  { render :layout => false }
      format.atom
      format.csv
    end
  end

  # GET /reserves/1
  # GET /reserves/1.json
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.json { render :json => @reserve.to_json }
    end
  end

  # GET /reserves/new
  def new
    if params[:reserve]
      user = User.where(:user_number => params[:reserve][:user_number]).first
    end
    user = @user if @user
    unless current_user.has_role?('Librarian')
      if user.try(:user_number).blank?
        access_denied; return
      end
      if user.blank? or user != current_user
        access_denied
        return
      end
    end

    if user
      @reserve = user.reserves.new
    else
      @reserve = Reserve.new
    end

    get_manifestation
    if @manifestation
      @reserve.manifestation = @manifestation
      if user
        @reserve.expired_at = @manifestation.reservation_expired_period(user).days.from_now.end_of_day
        if @manifestation.is_reserved_by?(user)
          flash[:notice] = t('reserve.this_manifestation_is_already_reserved')
          redirect_to @manifestation
          return
        end
      end
    end
  end

  # GET /reserves/1;edit
  def edit
  end

  # POST /reserves
  # POST /reserves.json
  def create
    if params[:reserve]
      user = User.where(:user_number => params[:reserve][:user_number]).first
    end
    # 図書館員以外は自分の予約しか作成できない
    unless current_user.has_role?('Librarian')
      unless user == current_user
        access_denied
        return
      end
    else
      user = @user if @user
    end

    @reserve = Reserve.new(params[:reserve])
    @reserve.user = user

    respond_to do |format|
      if @reserve.save
        # 予約受付のメール送信
        #unless user.email.blank?
        #  ReservationNotifier.deliver_accepted(user, @reserve.manifestation)
        #end
        @reserve.send_message('accepted')

        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.reserve'))
        #format.html { redirect_to reserve_url(@reserve) }
        format.html { redirect_to(@reserve) }
        format.json { render :json => @reserve, :status => :created, :location => reserve_url(@reserve) }
      else
        format.html { render :action => "new" }
        format.json { render :json => @reserve.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /reserves/1
  # PUT /reserves/1.json
  def update
    if params[:reserve][:user_number]
      user = User.where(:user_number => params[:reserve][:user_number]).first
    end

    if user
      if user != @reserve.user
        access_denied
        return
      end
    end

    if params[:mode] == 'cancel'
      @reserve.sm_cancel!
    end

    respond_to do |format|
      if @reserve.update_attributes(params[:reserve])
        if @reserve.state == 'canceled'
          flash[:notice] = t('reserve.reservation_was_canceled')
          #@reserve.send_message('canceled')
        else
          flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.reserve'))
        end
        format.html { redirect_to(@reserve) }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @reserve.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /reserves/1
  # DELETE /reserves/1.json
  def destroy
    @reserve.destroy
    #flash[:notice] = t('reserve.reservation_was_canceled')

    if @reserve.manifestation.is_reserved?
      if @reserve.item
        retain = @reserve.item.retain(User.find(1)) # TODO: システムからの送信ユーザの設定
        if retain.nil?
          flash[:message] = t('reserve.this_item_is_not_reserved')
        end
      end
    end

    respond_to do |format|
      flash[:notice] = t('controller.successfully_deleted', :model => t('activerecord.models.reserve'))
      format.html { redirect_to user_reserves_url(@user) }
      format.json { head :ok }
    end
  end
end

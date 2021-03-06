class ResponsesController < ApplicationController
  # GET /responses
  # GET /responses.json
  def index

    if params[:page].nil?
    # 検索条件の設定
    # ページ繰り以外
      @searched = Hash.new()
      session[:searched] = @searched
	  	
	  if !params[:search].nil?
	  # 検索ボタン押下時：画面入力された条件のセッションへの保存
        params[:search].each do | key, value |
        @searched.store(key, value)
        end
	  end
	  	
	else
	  # ページ繰り時：検索条件のセッションからの取り出し
      @searched = session[:searched]
	end
	
    if params[:request_id].nil?    
    # アンケート依頼に対する回答一覧以外（通常はこちら）
	  @responses = Response.all
      if current_user.isAuthor?
        @searched.store('user_id', current_user.id)
	  end
    else
	# アンケート依頼に対する回答一覧
      request = RequestQuestionnaire.find(params[:request_id])
      if request
        @responses = request.responses
      else
        @responses = Array new
      end
    end
	
	# まずはページングを指示
    @responses = Response.paginate(:page => params[:page], :per_page => 10)

	# 検索条件が指定されていれば、抽出条件としてwhere句を追加
    # ユーザーID
    if !(@searched.fetch('user_id', nil).blank?)
      @responses = @responses.where('responses.user_id = ?', @searched.fetch('user_id'))
    end
    # プロジェクト名
    if !(@searched.fetch('pjName', nil).blank?)
      @responses = @responses.where('responses.pjName like ?', "%" + @searched.fetch('pjName')+ "%")
    end
    # 対象年
    if !(@searched.fetch('targetYear', nil).blank?)
      @responses = @responses.where('responses.targetYear = ?', @searched.fetch('targetYear'))
    end
    # 対象月
    if !(@searched.fetch('targetMonth', nil).blank?)
      @responses = @responses.where('responses.targetMonth = ?', @searched.fetch('targetMonth'))
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @responses }
    end
  end

  # GET /responses/1
  # GET /responses/1.json
  def show
    @response = Response.find(params[:id])
	# 直近のアンケート依頼のとり方は修正が必要
	  current_request 
	  
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @response }
    end
  end

  # GET /responses/new
  # GET /responses/new.json
  def new
    @response = Response.new
	  @response.user_id = current_user.id
	  @response.customer_id = current_user.customer_id
	  @response.pjName = current_user.recent_project
	
	  current_request
	  
	  @response.targetYear = @current_request.target_year
	  @response.targetMonth = @current_request.target_month
	  
	  @current_request.questionnaire.questionitems.each do |item|
	    responce_item = ResponseItem.new
		responce_item.question = item.question
		@response.response_items << responce_item
	  end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @response }
    end
  end

  # GET /responses/1/edit
  def edit
    @response = Response.find(params[:id])
	  current_request
  end

  # POST /responses
  # POST /responses.json
  def create
    @response = Response.new(params[:response])
    @response.request_questionnaire = current_request
	  current_user.request_questionnaire = nil
      current_user.save
	  
    respond_to do |format|
      if @response.save
        format.html { redirect_to @response, notice: 'Response was successfully created.' }
        format.json { render json: @response, status: :created, location: @response }
      else
        format.html { render action: "new" }
        format.json { render json: @response.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /responses/1
  # PUT /responses/1.json
  def update
    @response = Response.find(params[:id])

    respond_to do |format|
      if @response.update_attributes(params[:response])
        format.html { redirect_to @response, notice: 'Response was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @response.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /responses/1
  # DELETE /responses/1.json
  def destroy
    @response = Response.find(params[:id])
    @response.response_items.destroy
    @response.destroy
    #アンケート依頼状態に戻す
	current_user.request_questionnaire = @request_questionnaire
    current_user.save
	
    respond_to do |format|
      format.html { redirect_to responses_url }
      format.json { head :no_content }
    end
  end
  def current_request
    # 直近のアンケート依頼のとり方は修正が必要
    @current_request = current_user.request_questionnaire
  end
end

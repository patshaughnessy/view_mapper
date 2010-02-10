class SomeOtherModelsController < ApplicationController

  auto_complete_for :parent, :name
  auto_complete_for :second_parent, :other_field

  # GET /some_other_models
  # GET /some_other_models.xml
  def index
    @some_other_models = SomeOtherModel.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @some_other_models }
    end
  end

  # GET /some_other_models/1
  # GET /some_other_models/1.xml
  def show
    @some_other_model = SomeOtherModel.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @some_other_model }
    end
  end

  # GET /some_other_models/new
  # GET /some_other_models/new.xml
  def new
    @some_other_model = SomeOtherModel.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @some_other_model }
    end
  end

  # GET /some_other_models/1/edit
  def edit
    @some_other_model = SomeOtherModel.find(params[:id])
  end

  # POST /some_other_models
  # POST /some_other_models.xml
  def create
    @some_other_model = SomeOtherModel.new(params[:some_other_model])

    respond_to do |format|
      if @some_other_model.save
        flash[:notice] = 'SomeOtherModel was successfully created.'
        format.html { redirect_to(@some_other_model) }
        format.xml  { render :xml => @some_other_model, :status => :created, :location => @some_other_model }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @some_other_model.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /some_other_models/1
  # PUT /some_other_models/1.xml
  def update
    @some_other_model = SomeOtherModel.find(params[:id])

    respond_to do |format|
      if @some_other_model.update_attributes(params[:some_other_model])
        flash[:notice] = 'SomeOtherModel was successfully updated.'
        format.html { redirect_to(@some_other_model) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @some_other_model.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /some_other_models/1
  # DELETE /some_other_models/1.xml
  def destroy
    @some_other_model = SomeOtherModel.find(params[:id])
    @some_other_model.destroy

    respond_to do |format|
      format.html { redirect_to(some_other_models_url) }
      format.xml  { head :ok }
    end
  end
end

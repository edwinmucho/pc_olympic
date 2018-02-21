require 'test_helper'

class KakaosControllerTest < ActionController::TestCase
  setup do
    @kakao = kakaos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:kakaos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create kakao" do
    assert_difference('Kakao.count') do
      post :create, kakao: {  }
    end

    assert_redirected_to kakao_path(assigns(:kakao))
  end

  test "should show kakao" do
    get :show, id: @kakao
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @kakao
    assert_response :success
  end

  test "should update kakao" do
    patch :update, id: @kakao, kakao: {  }
    assert_redirected_to kakao_path(assigns(:kakao))
  end

  test "should destroy kakao" do
    assert_difference('Kakao.count', -1) do
      delete :destroy, id: @kakao
    end

    assert_redirected_to kakaos_path
  end
end

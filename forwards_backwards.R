forwards_backwards <- function(prior, transmat, f_tk){ 
  #[tau_tk, xi_ikl, alpha, beta, loglik] = forwards_backwards(prior, transmat, fik, filter_only) 
  # forwards_backwards : calculates the E-step of the EM algorithm for an HMM
  # (Gaussian HMM)
  
  # Inputs :
  #
  #         prior(k) = Pr(z_1 = k)
  #         transmat(\ell,k) = Pr(z_t=k | z_{t-1} = \ell)
  #         f_tk(t,k) = Pr(y_t | z_y=k;\theta) %gaussian
  #
  # Outputs:
  #
  #        tau_tk(t,k) = Pr(z_t=k | X): post probs (smoothing probs)
  #        xi_tk\elll(t,k,\ell)  = Pr(z_t=k, z_{t-1}=\ell | Y) t =2,..,n
  #        with Y = (y_1,...,y_n);
  #        alpha_tk: [nxK], forwards probs: Pr(y1...yt,zt=k)
  #        beta_tk: [nxK], backwards probs: Pr(yt+1...yn|zt=k)
  #
  #
  #
  # Faicel Chamroukhi
  ##############################################################################
  N = nrow(f_tk)
  K = ncol(f_tk)
  if (nargs() < 6){ filter_only = 0}
  
  scale = matrix(c(1),nrow=1,ncol=N) #pour que loglik = sum(log(scale)) part de zero
  
  prior = prior
  tau_tk = matrix(data=0,nrow=N,ncol=K)
  xi_tkl = array(data=0,dim=c(N-1,K,K))
  alpha_tk = matrix(data=0,nrow=N,ncol=K)
  beta_tk = matrix(data=0,nrow=N,ncol=K)

  ## forwards: calculation of alpha_tk
  t = 1
  alpha_tk[t,] = t(prior)*f_tk[t,]
  #print(alpha_tk[t,])
  alpha_tk[t,]= normalise(alpha_tk[t,])[[1]]
  #print(alpha_tk[1,])
  scale[t] = normalise(alpha_tk[t,])[[2]]
  #print(scale[1])
  
  for (t in 2:N){
    alpha_tk[t,] = normalise((alpha_tk[t-1,]%*%transmat)*f_tk[t,])[[1]]
    scale[t] = normalise((alpha_tk[t-1,]%*%transmat) * f_tk[t,])[[2]]
    #filtered_prob (t-1,:,:)= normalise((alpha(:,t-1) * fik(:,t)') .*transmat)
  }
  ##loglikehood (with the scaling technique) (see Rabiner's paper/book)
  loglik = sum(log(scale))
  
  if (filter_only){
    beta_tk = NULL
    xi_tkl = alpha_tk
  }
  ## backwards: calculation of beta_tk, tau_tk (and xi_tkl)
  #t=T
  beta_tk[N,] = matrix(c(1),1,K)
  
  tau_tk[N,] = normalise(alpha_tk[N,]*beta_tk[N,])[[1]]
  
  
  for (t in (N-1):1){
     beta_tk[t,] =  round(normalise(transmat %*% (beta_tk[t+1,]*f_tk[t+1,]))[[1]],4)
     # transmat * t(beta[t+1,] %*% fik[t+1,]) /scale[t] 
     tau_tk[t,] = round(normalise(alpha_tk[t,] * beta_tk[t,])[[1]],4)
     xi_tkl[t,,] = round(normalise(transmat * (as.matrix(alpha_tk[t,])%*%t(as.matrix(beta_tk[t+1,] * f_tk[t+1,]))))[[1]],4)
  }

  return(list(tau_tk=tau_tk,xi_tkl=xi_tkl,alpha_tk=alpha_tk,beta_tk=beta_tk,loglik=loglik))
}



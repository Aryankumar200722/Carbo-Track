(()=> {
 const $=s=>document.querySelector(s);
 const cfg=window.CARBOTRACK_CONFIG||{};
 const ready=!!(cfg.supabaseUrl&&cfg.supabaseAnonKey&&window.supabase);
 const sb=ready?window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey):null;
 let adminMode="login";
 const show=(id,message,type="")=>{const el=$(id);el.textContent=message;el.className="auth-msg "+type};
 document.querySelectorAll("[data-access]").forEach(btn=>btn.addEventListener("click",()=>{
   document.querySelectorAll("[data-access]").forEach(b=>b.classList.toggle("active",b===btn));
   document.querySelectorAll(".access-panel").forEach(p=>p.classList.remove("active"));
   $("#"+btn.dataset.access+"-panel").classList.add("active");
 }));
 $("#admin-signup-toggle").addEventListener("click",()=>{
   adminMode=adminMode==="login"?"signup":"login";
   $("#admin-name-wrap").classList.toggle("hidden",adminMode!=="signup");
   $("#admin-submit").textContent=adminMode==="signup"?"Create administrator account ↗":"Sign in as administrator ↗";
   $("#admin-signup-toggle").textContent=adminMode==="signup"?"Back to administrator sign in":"Create the first administrator account";
   $("#admin-password").autocomplete=adminMode==="signup"?"new-password":"current-password";
   show("#admin-message","");
 });
 $("#admin-form").addEventListener("submit",async e=>{
   e.preventDefault();if(!ready){show("#admin-message","Supabase is not configured.","error");return}
   const button=$("#admin-submit");button.disabled=true;
   try{
     const email=$("#admin-email").value.trim(),password=$("#admin-password").value;
     if(adminMode==="signup"){
       const fullName=$("#admin-name").value.trim();
       if(!fullName)throw new Error("Enter the administrator's full name.");
       const {data,error}=await sb.auth.signUp({email,password,options:{data:{full_name:fullName,carbotrack_admin:true}}});
       if(error)throw error;
       if(data.session){location.href="organization.html";return}
       show("#admin-message","Administrator account created. Verify the email, then sign in here.","ok");
     }else{
       const {data,error}=await sb.auth.signInWithPassword({email,password});if(error)throw error;
       const {data:membership,error:memberError}=await sb.from("organization_members").select("organization_id,role").eq("user_id",data.user.id).limit(1);
       if(memberError)throw memberError;
       if(!membership?.length){location.href="organization.html";return}
       location.href="dashboard.html";
     }
   }catch(err){show("#admin-message",err.message||"Administrator sign-in failed.","error")}
   finally{button.disabled=false}
 });
 $("#staff-form").addEventListener("submit",async e=>{
   e.preventDefault();if(!ready){show("#staff-message","Supabase is not configured.","error");return}
   const button=$("#staff-submit");button.disabled=true;
   try{
     const staffCode=$("#staff-code").value.trim().toUpperCase(),pin=$("#staff-pin").value;
     const {data,error}=await sb.functions.invoke("staff-login",{body:{staffCode,pin}});
     if(error)throw new Error(data?.error||error.message||"Staff sign-in failed.");
     if(data?.error)throw new Error(data.error);
     if(!data?.access_token||!data?.refresh_token)throw new Error("The staff login did not return a valid session.");
     const {error:sessionError}=await sb.auth.setSession({access_token:data.access_token,refresh_token:data.refresh_token});
     if(sessionError)throw sessionError;
     location.href="dashboard.html";
   }catch(err){show("#staff-message",err.message||"Staff sign-in failed.","error")}
   finally{button.disabled=false}
 });
})();
//
//  SelectBankTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 7/2/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit

class SelectBankTableViewController: UITableViewController {
    
    var selectedBank = [String: String]()
    
    let banks = [
    [
        "bank_code": "ally",
        "bank_name": "Ally Bank",
        "forgotten_password": "https://www.ally.com/",
        "logo": "https://cdn.synapsepay.com/bank_logos/ally.png"
        ],
    [
        "bank_code": "bangor",
        "bank_name": "Bangor Savings Bank",
        "forgotten_password": "https://www.bangoronlinebanking.com/tob/live/usp-core/app/authUpdate",
        "logo": "https://cdn.synapsepay.com/bank_logos/bangor.jpg"
        ],
    [
        "bank_code": "bbt",
        "bank_name": "BB&T Bank",
        "forgotten_password": "https://online.bbt.com/bbtpassreset/",
        "logo": "https://cdn.synapsepay.com/bank_logos/bbt.png"
        ],
    [
        "bank_code": "bofa",
        "bank_name": "Bank of America",
        "forgotten_password": "https://secure.bankofamerica.com/login/reset/entry/forgotPwdScreen.go",
        "logo": "https://cdn.synapsepay.com/bank_logos/bofa.png"
        ],
    [
        "bank_code": "boftw",
        "bank_name": "Bank of the West",
        "forgotten_password": "https://online.bankofthewest.com/BOW/ForgottenPassword/ForgotPassword.aspx",
        "logo": "https://cdn.synapsepay.com/bank_logos/bofw.png"
        ],
    [
        "bank_code": "capone",
        "bank_name": "Capital One",
        "forgotten_password": "https://verified.capitalone.com/signinhelp.html",
        "logo": "https://cdn.synapsepay.com/bank_logos/capone.jpg"
        ],
    [
        "bank_code": "capone360",
        "bank_name": "Capital One 360",
        "forgotten_password": "https://verified.capitalone.com/signinhelp.html",
        "logo": "https://cdn.synapsepay.com/bank_logos/cap360.png"
        ],
    [
        "bank_code": "centralillinois",
        "bank_name": "Central Bank Illinois",
        "forgotten_password": "https://secure.fundsxpress.com/piles/resetpass.pile/identify?iid=CBIGIL",
        "logo": "https://cdn.synapsepay.com/bank_logos/centralillinois.png"
        ],
    [
        "bank_code": "chase",
        "bank_name": "Chase",
        "forgotten_password": "https://chaseonline.chase.com/Public/ReIdentify/ReidentifyFilterView.aspx?COLLogon",
        "logo": "https://cdn.synapsepay.com/bank_logos/chase.png"
        ],
    [
        "bank_code": "citi",
        "bank_name": "Citibank",
        "forgotten_password": "https://online.citi.com/US/JSO/uidn/RequestUserIDReminder.do",
        "logo": "https://cdn.synapsepay.com/bank_logos/citi.png"
        ],
    [
        "bank_code": "citizens",
        "bank_name": "Citizens Bank",
        "forgotten_password": "https://www3.citizensbankonline.com/efs/servlet/efs/login-assistance.jsp",
        "logo": "https://cdn.synapsepay.com/bank_logos/citizens.jpg"
        ],
    [
        "bank_code": "cu1",
        "bank_name": "Credit Union 1 (AK)",
        "forgotten_password": "https://ola.cu1.org/ForgotPassword",
        "logo": "https://cdn.synapsepay.com/bank_logos/cu1.jpg"
        ],
    [
        "bank_code": "fidelity",
        "bank_name": "Fidelity",
        "forgotten_password": "https://login.fidelity.com/ftgw/Fas/Fidelity/RtlCust/IdentifyUser/Init/?",
        "logo": "https://cdn.synapsepay.com/bank_logos/fidelity.png"
        ],
    [
        "bank_code": "firsttennessee",
        "bank_name": "First Tennessee",
        "forgotten_password": "https://security.firsttennessee.com/fhnsso/rlogin.do?execution=e1s1",
        "logo": "https://cdn.synapsepay.com/bank_logos/first_tn.png"
        ],
    [
        "bank_code": "kembafcu",
        "bank_name": "Kemba Financial Credit Union",
        "forgotten_password": "https://online.kemba.org/User/AccessSigninResetPassword/Start",
        "logo": "https://cdn.synapsepay.com/bank_logos/kembafcu.png"
        ],
    [
        "bank_code": "lbsfcu",
        "bank_name": "LBS Financial Credit Union",
        "forgotten_password": "http://www.lbsfcu.org/",
        "logo": "https://cdn.synapsepay.com/bank_logos/lbsfcu.jpg"
        ],
    [
        "bank_code": "nevadastate",
        "bank_name": "Nevada State Bank",
        "forgotten_password": "https://securentry.nsbank.com/passreset/",
        "logo": "https://cdn.synapsepay.com/bank_logos/nevadastate.png"
        ],
    [
        "bank_code": "nfcu",
        "bank_name": "Navy Federal Credit Union",
        "forgotten_password": "https://my.navyfederal.org/NFOAA_Auth/login.jsp",
        "logo": "https://cdn.synapsepay.com/bank_logos/nfcu.jpg"
        ],
    [
        "bank_code": "pffcu",
        "bank_name": "Police and Fire Federal Credit Union",
        "forgotten_password": "https://www.pffcu.org/",
        "logo": "https://cdn.synapsepay.com/bank_logos/pffcu.jpg"
        ],
    [
        "bank_code": "pnc",
        "bank_name": "PNC Bank",
        "forgotten_password": "https://www.onlinebanking.pnc.com/alservlet/ForgotUserIdServlet",
        "logo": "https://cdn.synapsepay.com/bank_logos/pnc.png"
        ],
    [
        "bank_code": "regions",
        "bank_name": "Regions",
        "forgotten_password": "https://onlinebanking.regions.com/customerservice/forgottenpassword",
        "logo": "https://cdn.synapsepay.com/bank_logos/regionsbank.png"
        ],
    [
        "bank_code": "schwab",
        "bank_name": "Charles Schwab",
        "forgotten_password": "https://client.schwab.com/Areas/Login/ForgotPassword/FYPIdentification.aspx",
        "logo": "https://cdn.synapsepay.com/bank_logos/charles_schwab.png"
        ],
    [
        "bank_code": "simple",
        "bank_name": "Simple",
        "forgotten_password": "https://bank.simple.com/forgot-passphrase",
        "logo": "https://cdn.synapsepay.com/bank_logos/simple.png"
        ],
    [
        "bank_code": "suntrust",
        "bank_name": "SunTrust Bank",
        "forgotten_password": "https://onlinebanking.suntrust.com/UI/login#/forgotcredentials",
        "logo": "https://cdn.synapsepay.com/bank_logos/suntrust.png"
        ],
    [
        "bank_code": "svb",
        "bank_name": "Silicon Valley Bank",
        "forgotten_password": "https://www.svbconnect.com/auth/",
        "logo": "https://cdn.synapsepay.com/bank_logos/svb.jpg"
        ],
    [
        "bank_code": "td",
        "bank_name": "TD Bank",
        "forgotten_password": "https://onlinebanking.tdbank.com/",
        "logo": "https://cdn.synapsepay.com/bank_logos/td.png"
        ],
    [
        "bank_code": "ukfcu",
        "bank_name": "University of Kentucky FCU",
        "forgotten_password": "https://olb.ukfcu.org/User/AccessSigninResetPassword/Start",
        "logo": "https://cdn.synapsepay.com/bank_logos/ukfcu.jpg"
        ],
    [
        "bank_code": "union",
        "bank_name": "Union Bank",
        "forgotten_password": "https://sso.unionbank.com/unp/havingtrouble.jsp",
        "logo": "https://cdn.synapsepay.com/bank_logos/unionbank.png"
        ],
    [
        "bank_code": "us",
        "bank_name": "US Bank",
        "forgotten_password": "https://onlinebanking.usbank.com/OLS/LoginAssist/RetriveId#/RetrievePersonalId",
        "logo": "https://cdn.synapsepay.com/bank_logos/usbank.png"
        ],
    [
        "bank_code": "usaa",
        "bank_name": "USAA",
        "forgotten_password": "https://www.usaa.com/inet/ent_proof/proofingEvent?action=Init&event=forgotPassword&wa_ref=pub_auth_nav_forgotpwd",
        "logo": "https://cdn.synapsepay.com/bank_logos/usaa.png"
        ],
    [
        "bank_code": "wells",
        "bank_name": "Wells Fargo",
        "forgotten_password": "https://www.wellsfargo.com/help/faqs/sign-on",
        "logo": "https://cdn.synapsepay.com/bank_logos/wells_fargo.png"
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return banks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Configure the cell...
        let bank = banks[indexPath.row]
        let url = URL(string: bank["logo"]!)
        
        let image = cell.viewWithTag(100) as! UIImageView
        image.clipsToBounds = true
        image.layer.cornerRadius = 20
        image.imageFromServerURL(url) { 
            // Do something
        }
        
        let title = cell.viewWithTag(101) as! UILabel
        title.text = bank["bank_name"]
     
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedBank = banks[indexPath.row]
        self.performSegue(withIdentifier: "showBankLogin", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "showBankLogin") {
            let destViewController = segue.destination as! BankLoginTableViewController
            destViewController.selectedBank = selectedBank
        }
    }

}
